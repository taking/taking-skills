# Tunnel Service (gRPC) Reference

## Overview

Control Plane과 Cluster Agent 사이의 reverse tunnel RPC. Agent가 `Connect`로 bidi stream을 열면, Control Plane이 그 stream 위로 Kubernetes API 요청을 실어 보내고 Agent가 응답을 되돌립니다.

- Package: `tunnel.v1`
- Transport: HTTP/2, TLS (mTLS)
- Stream: Agent-initiated, long-lived

## Auth

| 항목 | 값 |
| --- | --- |
| 방식 | mTLS (client cert) |
| Cert 발급 | Control Plane CA가 cluster별로 발급 |
| 식별자 | cert SAN의 `cluster_id` |
| 만료 | 24h, Agent가 자동 갱신 |

## RPCs

| RPC | 타입 | 방향 | 설명 |
| --- | --- | --- | --- |
| `Connect` | bidi stream | Agent → CP | tunnel 수립, 요청/응답 교환 |
| `Heartbeat` | unary | Agent → CP | liveness 보고 (10s 주기) |
| `Report` | client stream | Agent → CP | 초기 cluster 메타 전송 |

## Message Schema

`Connect`의 stream 메시지 (`Frame`):

| 필드 | 타입 | 방향 | 설명 |
| --- | --- | --- | --- |
| `request_id` | string | 양방향 | 요청-응답 상관 키 |
| `method` | string | CP → Agent | HTTP method (GET/POST 등) |
| `path` | string | CP → Agent | API server 경로 |
| `body` | bytes | 양방향 | 요청, 응답 payload chunk |
| `status` | int32 | Agent → CP | HTTP status code |
| `eof` | bool | 양방향 | 해당 request_id의 마지막 frame |

## Errors

| gRPC code | 상황 | Agent 동작 |
| --- | --- | --- |
| `UNAUTHENTICATED` | cert 만료, 무효 | cert 갱신 후 재연결 |
| `UNAVAILABLE` | CP 재시작, 네트워크 | exponential backoff 재연결 |
| `RESOURCE_EXHAUSTED` | 동시 stream 한도 초과 | jitter backoff 후 재시도 |
| `DEADLINE_EXCEEDED` | 요청 처리 초과 | 해당 request_id만 실패 처리 |

## Examples

Proto 정의:

```protobuf
service TunnelService {
  rpc Connect(stream Frame) returns (stream Frame);
  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatReply);
}

message Frame {
  string request_id = 1;
  string method = 2;
  string path = 3;
  bytes body = 4;
  int32 status = 5;
  bool eof = 6;
}
```

Agent 연결 (Go):

```go
stream, err := client.Connect(ctx)
if err != nil {
    return fmt.Errorf("connect tunnel: %w", err)
}
for {
    frame, err := stream.Recv()
    if err == io.EOF {
        return nil
    }
    if err != nil {
        return err // caller가 backoff 재연결
    }
    go proxy.Handle(stream, frame) // in-cluster API server로 전달
}
```

## References

- [gRPC Status Codes](https://grpc.io/docs/guides/status-codes/)
- [Protocol Buffers Language Guide (proto3)](https://protobuf.dev/programming-guides/proto3/)
