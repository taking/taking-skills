# grpc 템플릿

gRPC service, RPC의 doc-comment. wire 계약을 적습니다: streaming 방향, deadline, idempotency, 반환하는 status code, 스키마 호환성. 이것들은 코드에 안 보이므로 문서가 유일한 계약입니다.

## 왜/언제

- **언제**: `.proto`의 service, rpc 정의, 또는 생성 스텁을 감싸는 서버 메서드.
- **왜**: 클라이언트는 proto만 보고 재시도, 타임아웃, 에러 처리를 결정합니다. idempotency와 status code 계약이 없으면 재시도가 데이터를 중복시키거나 지웁니다.
- **적을 것**: streaming(unary/server/client/bidi), deadline 기대치, idempotent 여부(재시도 안전), 반환 status code와 의미, 필드 추가/삭제 호환성.

## 스켈레톤 (`.proto`)

```protobuf
// <Service> <목적, 경계>.
service <Service> {
  // <RPC> <무엇을 보장하는가>.
  //
  // Streaming: <unary | server-stream | client-stream | bidi>.
  // Deadline:  <권장 deadline. 초과 시 서버 동작>.
  // Idempotency: <idempotent → 재시도 안전 | non-idempotent → <dedup key> 필요>.
  // Errors:
  //   <CODE>  - <언제 반환하는가>.
  //   <CODE>  - <...>.
  // Compat: <필드 추가는 호환. 제거, 번호 재사용 금지 등 규칙>.
  rpc <RPC>(<Req>) returns (<Resp>);
}
```

## Good example

```protobuf
// AgentTunnel carries control-plane commands to a cluster agent and streams
// results back. One long-lived stream per connected agent.
service AgentTunnel {
  // Exec runs a command on the agent and streams stdout/stderr chunks until
  // the process exits.
  //
  // Streaming: server-stream (one ExecRequest, many ExecChunk).
  // Deadline:  caller sets the deadline to the command timeout; the agent
  //            kills the process and closes the stream when it elapses.
  // Idempotency: NOT idempotent. It launches a process. On reconnect the
  //            caller must supply request_id; the agent dedups replays and
  //            re-attaches to the running process instead of starting a new one.
  // Errors:
  //   FAILED_PRECONDITION - agent not registered for this cluster.
  //   PERMISSION_DENIED   - command not in the agent's allowlist.
  //   DEADLINE_EXCEEDED    - timeout elapsed; process was killed.
  // Compat: ExecChunk fields are append-only; existing tags are frozen.
  rpc Exec(ExecRequest) returns (stream ExecChunk);
}
```
