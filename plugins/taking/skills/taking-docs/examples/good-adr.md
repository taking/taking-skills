# ADR-004: Kafka payload로 protobuf 대신 JSON envelope 사용

- Status: Accepted
- Date: 2026-05-12

## Context

Cluster Agent가 resource 변경 이벤트를 Kafka로 publish하고, Control Plane과 하위 서비스 여러 개가 소비합니다.

- 소비자가 다수이고 팀이 다릅니다 (schema 조율 비용 큼)
- 이벤트 양은 중간 규모 (peak 수천 msg/s, 초저지연 요구 아님)
- 운영 중 payload를 눈으로 확인할 일이 잦습니다 (kafka-console-consumer, 로그)
- 사내 이벤트 표준이 JSON envelope 형태를 이미 규정합니다

## Decision

Kafka payload는 **JSON envelope**로 보냅니다. envelope는 공통 메타(`type`, `source`, `time`, `id`)와 도메인 `data`를 담습니다. protobuf는 tunnel RPC에만 쓰고 Kafka에는 쓰지 않습니다.

## Alternatives

| 방안 | 장점 | 단점 |
| --- | --- | --- |
| **JSON envelope** (선택) | 스키마 조율 느슨, 사람이 읽음, 표준 부합 | payload 큼, 파싱 CPU 높음 |
| Protobuf (schema registry) | 작고 빠름, 강한 스키마 | registry 운영 부담, 디버깅 시 역직렬화 필요 |
| Avro (schema registry) | compact, 스키마 진화 지원 | Kafka 생태계 밖 소비자 연동 복잡 |

## Consequences

| | 결과 |
| --- | --- |
| + | 새 소비자가 스키마 등록 없이 붙습니다 |
| + | 운영 중 이벤트를 그대로 읽어 디버깅합니다 |
| + | 사내 이벤트 표준 검증 도구를 그대로 씁니다 |
| − | 동일 이벤트가 protobuf 대비 3~5배 큽니다 |
| − | 필드 오타, 타입 오류를 런타임에야 잡습니다 (JSON Schema 검증으로 완화) |
| − | 초고throughput topic이 생기면 재검토가 필요합니다 |

## References

- [CloudEvents Spec](https://github.com/cloudevents/spec)
- [Confluent: Schema Management](https://docs.confluent.io/platform/current/schema-registry/index.html)
