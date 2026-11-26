# <도메인> Kafka Events

<!-- 채우기: H1은 이벤트 도메인. "<도메인> Kafka Events". -->

## Overview

<!-- 채우기: 어떤 이벤트 흐름인가. 발행자, 소비자. 3~6줄 또는 표. -->
| 항목 | 값 |
| --- | --- |
| 발행자 | `<producer>` |
| 소비자 | `<consumer>` |
| 직렬화 | `<JSON / Avro / protobuf>` |

## Topics

<!-- 채우기: 토픽 목록은 반드시 표. -->
| 토픽 | 용도 | 파티션 키 | 보존 |
| --- | --- | --- | --- |
| `<topic.name>` | `<용도>` | `<key>` | `<7d>` |

## Event schema / Envelope

<!-- 채우기: 공통 envelope + payload 필드를 표로. -->
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `eventId` | `string` | `<고유 ID>` |
| `eventType` | `string` | `<이벤트 타입>` |
| `occurredAt` | `string` | `<RFC3339>` |
| `payload` | `object` | `<도메인 데이터>` |

```json
{
  "eventId": "<uuid>",
  "eventType": "<domain.action>",
  "occurredAt": "<2026-01-01T00:00:00Z>",
  "payload": { "<field>": "<value>" }
}
```

## Delivery semantics

<!-- 채우기: 전달 보장은 반드시 표. -->
| 항목 | 정책 |
| --- | --- |
| 전달 보장 | `<at-least-once>` |
| 멱등성 | `<eventId 기준 dedup>` |
| 순서 | `<파티션 키 내 보장>` |
| DLQ | `<topic.name.dlq, 재시도 N회 후>` |

## Consumer groups

| group | 토픽 | 처리 |
| --- | --- | --- |
| `<group-id>` | `<topic>` | `<처리 내용>` |

## Examples

```go
msg := kafka.Message{
    Key:   []byte("<key>"),
    Value: payload,
}
if err := writer.WriteMessages(ctx, msg); err != nil {
    return fmt.Errorf("publish failed: %w", err)
}
```

## References

- [<이벤트 표준 / 스키마 레지스트리>](<경로>)
