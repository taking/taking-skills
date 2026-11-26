# <Service> gRPC API

<!-- 채우기: H1은 gRPC 서비스 이름. "<Service> gRPC API". -->

## Overview

<!-- 채우기: 무슨 서비스인가. proto 패키지, 위치. 표 권장. -->
| 항목 | 값 |
| --- | --- |
| proto package | `<xpu.v1>` |
| service | `<ServiceName>` |
| 전송 | `<tunnel / mTLS 등>` |

## Service / RPCs

<!-- 채우기: RPC 목록은 반드시 표. -->
| RPC | 요청 | 응답 | 유형 |
| --- | --- | --- | --- |
| `<Rpc1>` | `<Req>` | `<Resp>` | unary |
| `<Rpc2>` | `<Req>` | stream `<Resp>` | server-stream |
| `<Rpc3>` | stream `<Req>` | stream `<Resp>` | bidi-stream |

## Messages

<!-- 채우기: 메시지 필드는 표. -->
| 메시지 | 필드 | 타입 | 설명 |
| --- | --- | --- | --- |
| `<Req>` | `<field>` | `string` | `<설명>` |
| `<Resp>` | `<field>` | `int32` | `<설명>` |

## Streaming semantics

<!-- 채우기: 스트리밍 동작. 표 또는 짧은 bullet. -->
| 항목 | 동작 |
| --- | --- |
| 순서 보장 | `<보장 / 미보장>` |
| 종료 | `<half-close, CloseSend>` |
| keepalive | `<간격>` |
| backpressure | `<처리>` |

## Errors

<!-- 채우기: gRPC status code 표. -->
| code | 의미 | 조치 |
| --- | --- | --- |
| `INVALID_ARGUMENT` | `<의미>` | `<조치>` |
| `UNAVAILABLE` | `<의미>` | `<재시도>` |
| `DEADLINE_EXCEEDED` | `<의미>` | `<조치>` |

## Example

```protobuf
service <ServiceName> {
  rpc <Rpc1>(<Req>) returns (<Resp>);
}

message <Req> {
  string <field> = 1;
}
```

```go
resp, err := client.<Rpc1>(ctx, &pb.<Req>{<Field>: "<value>"})
if err != nil {
    return fmt.Errorf("<rpc> failed: %w", err)
}
```

## References

- [<proto 파일 / 스펙>](<경로>)
