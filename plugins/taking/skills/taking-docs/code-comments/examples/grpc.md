# grpc : 서비스, RPC 계약 문서화

gRPC/Protobuf에서 문서화할 계약: **스트리밍 방향, 수명, deadline, 멱등성, 에러 코드, 필드 번호 안정성.** 코드는 이걸 말하지 않습니다.

---

## 목차

- 1. Protobuf : 서비스, 메시지 계약
  - Before
  - Review
  - After
- 2. Go : 서버 스트림 핸들러
  - Before
  - Review
  - After

## 1. Protobuf : 서비스, 메시지 계약

### Before

```protobuf
syntax = "proto3";

package xpu.tunnel.v1;

// tunnel service
service Tunnel {
  // open a tunnel
  rpc Open(stream Frame) returns (stream Frame);
  // send status
  rpc ReportStatus(StatusRequest) returns (StatusReply);
}

// a frame
message Frame {
  bytes payload = 1;
  string session_id = 2;
  int64 seq = 3;
}
```

### Review
**Remove [should]** : `// tunnel service`, `// open a tunnel`, `// a frame`는 식별자 재진술이라 삭제. **Add [must-fix]** : `Open`은 양방향 스트림인데 **누가 먼저 보내는지, 스트림 수명, half-close 의미**가 없습니다. 스트리밍 RPC의 계약이 비어 있습니다. **Add [must-fix]** : 에러 코드 규약이 없습니다. 재접속 로직이 `UNAVAILABLE`(재시도 OK)과 `FAILED_PRECONDITION`(재시도 무의미)을 구분해야 하므로 어떤 코드가 무엇을 뜻하는지 문서화합니다. **Add [must-fix]** : **필드 번호 안정성**은 wire 호환성의 핵심입니다. 재사용 금지, reserved 정책이 명시돼야 합니다. **Add [should]** : `ReportStatus`의 멱등성(같은 seq 재전송 시 동작)이 불명확합니다.

### After

```protobuf
syntax = "proto3";

package xpu.tunnel.v1;

// Tunnel carries opaque control-plane traffic over a reverse gRPC stream
// initiated by the in-cluster agent.
service Tunnel {
  // Open establishes the bidirectional tunnel. The agent (client) sends the
  // first Frame to announce its session; the server replies on the same
  // stream. The stream lives for the whole agent connection; either side
  // half-closing tears it down and the agent must re-dial.
  //
  // Errors: UNAVAILABLE = transient, re-dial with backoff.
  // FAILED_PRECONDITION = session rejected (e.g. tenant mismatch), do NOT retry.
  rpc Open(stream Frame) returns (stream Frame);

  // ReportStatus is idempotent: replaying the same (session_id, seq) is a
  // no-op on the server, so the agent may retry safely after UNAVAILABLE.
  rpc ReportStatus(StatusRequest) returns (StatusReply);
}

message Frame {
  // Field numbers are wire contract: never reuse or renumber. Add new fields
  // with the next free number and reserve removed ones.
  bytes payload = 1;      // opaque; the tunnel never parses this
  string session_id = 2;
  int64 seq = 3;          // per-session monotonic; used for dedupe
  // reserved 4 to 8;  // (example) removed fields go here
}
```

---

## 2. Go : 서버 스트림 핸들러

### Before

```go
// Open handles the tunnel stream.
func (s *tunnelServer) Open(stream pb.Tunnel_OpenServer) error {
	for {
		f, err := stream.Recv()
		if err != nil {
			return err
		}
		if err := s.route(f); err != nil {
			return err
		}
	}
}
```

### Review
**Remove [should]** : `// Open handles the tunnel stream.`는 메서드명 재진술 + AI투 동사. 삭제. **Improve Code [must-fix]** : `io.EOF`(정상 half-close)를 일반 에러처럼 반환합니다. gRPC에선 `Recv`가 EOF를 주면 정상 종료이므로 `nil`을 반환해야 합니다. 계약 위반. **Add [must-fix]** : deadline/취소 계약이 없습니다. `stream.Context()` 취소 시 어떻게 정리하는지, `route` 실패를 어떤 gRPC status로 사상하는지 문서화. **Add [should]** : 첫 프레임이 세션을 확립한다는 프로토콜 순서(proto와 일치)를 재확인.

### After

```go
// Open serves one reverse tunnel: the agent sends the first Frame to
// establish the session, then streams frames until it half-closes (io.EOF,
// returned as nil) or stream.Context() is cancelled. A routing failure is
// surfaced as a gRPC status so the agent can distinguish retryable
// (UNAVAILABLE) from terminal (FAILED_PRECONDITION) errors.
func (s *tunnelServer) Open(stream pb.Tunnel_OpenServer) error {
	for {
		f, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return nil // agent half-closed: normal shutdown
		}
		if err != nil {
			return err
		}
		if err := s.route(stream.Context(), f); err != nil {
			return status.Errorf(codes.FailedPrecondition, "route frame: %v", err)
		}
	}
}
```
