# grpc (서비스, RPC 계약 문서화)

`.proto`의 service/rpc 주석은 클라이언트가 의존하는 계약입니다. 스트리밍, 데드라인, 멱등성, 에러 매핑, 호환성을 반드시 적습니다.

---

## 1. 스트리밍 방향과 종료 조건을 적습니다

누가 언제 스트림을 닫는지, half-close 규약을 명시합니다.

```protobuf
// Bad: 스트리밍 방향과 수명이 불명
rpc Tunnel(stream Frame) returns (stream Frame);

// Good: 방향, 소유권, 종료 계약
// Tunnel establishes the reverse channel: the agent dials in and the control
// plane multiplexes apiserver requests over it. Bidirectional and long-lived.
// The agent half-closes on graceful shutdown; the server closes only on
// clusterId revocation. Either side seeing io.EOF must treat the tunnel as gone
// and re-dial with backoff.
rpc Tunnel(stream Frame) returns (stream Frame);
```

## 2. 데드라인, 취소 동작을 문서화합니다

취소, 데드라인 초과 시 서버가 부수효과를 롤백하는지 여부를 밝힙니다.

```protobuf
// Good
// ApplyManifest forwards the manifest to the target apiserver.
// Honors the client deadline: if it expires mid-apply the server returns
// DEADLINE_EXCEEDED but does NOT roll back partial applies — the caller must
// reconcile. Client cancellation is best-effort and equally non-transactional.
rpc ApplyManifest(ApplyRequest) returns (ApplyResponse);
```

## 3. 멱등성을 밝힙니다

재시도 안전 여부는 클라이언트 재시도 정책의 전제입니다.

```protobuf
// Bad: 재시도해도 되는지 알 수 없습니다
rpc RegisterCluster(RegisterRequest) returns (RegisterResponse);

// Good
// RegisterCluster is idempotent on request_id: repeating the same request_id
// returns the original registration instead of creating a duplicate.
// Safe to retry on UNAVAILABLE.
rpc RegisterCluster(RegisterRequest) returns (RegisterResponse);
```

## 4. status code 매핑을 정의합니다

어떤 도메인 실패가 어떤 `google.rpc.Code`로 오는지 계약으로 고정합니다.

```protobuf
// Good
// Returns:
//   NOT_FOUND        — no tunnel registered for cluster_id
//   FAILED_PRECONDITION — tunnel exists but is draining; retry after re-register
//   PERMISSION_DENIED — caller's mTLS identity is not bound to cluster_id
// UNAVAILABLE is transient and retryable; the codes above are not.
rpc GetTunnel(GetTunnelRequest) returns (Tunnel);
```

## 5. 하위 호환성 제약을 남깁니다

메서드, 필드 변경 시 wire 호환을 깨는지 경고합니다.

```protobuf
// Good
// NOTE: request_id was added in v1.3 and is optional for wire compatibility;
// pre-v1.3 agents send none and fall back to non-idempotent behavior.
// Do NOT make it required — that breaks the rolling upgrade path.
string request_id = 4;
```
