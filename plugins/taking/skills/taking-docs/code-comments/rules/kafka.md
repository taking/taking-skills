# kafka (토픽, 이벤트 계약 문서화)

topic 이름과 eventType은 프로듀서, 컨슈머가 공유하는 계약입니다. 엔벨로프 스키마, 파티션 키, 순서, 전달 시맨틱, DLQ, 컨슈머 그룹 가정을 문서화합니다.

---

## 1. topic, eventType을 계약으로 고정합니다

토픽 명명 규칙과 eventType 값 집합을 상수 옆에 남깁니다. 리네임은 소비자를 끊습니다.

```go
// Bad
const topic = "workload-events"

// Good: 명명 규칙, 소비자, 리네임 위험을 명시
// WorkloadTopic carries workload lifecycle events, one topic per tenant:
// "xpu.workload.<tenant>". Consumers subscribe by prefix. Renaming the prefix
// requires a coordinated cutover — do not change without a migration plan.
const WorkloadTopicPrefix = "xpu.workload."
```

## 2. 엔벨로프 스키마를 한 곳에 문서화합니다

공통 봉투(eventId, eventType, occurredAt, payload)의 각 필드 의미를 struct 옆에 둡니다.

```go
// Good
// Envelope is the on-wire contract for every message on xpu.workload.*.
// Serialized as JSON; field names are the contract (see json tags).
type Envelope struct {
    // EventID is the producer-generated ULID. Consumers dedup on it
    // (at-least-once delivery — the same EventID may arrive more than once).
    EventID string `json:"eventId"`
    // EventType is a stable dotted string, e.g. "workload.created".
    // Never repurpose a value; add a new one for new semantics.
    EventType string `json:"eventType"`
    // OccurredAt is event time (RFC 3339 UTC), NOT ingestion time.
    OccurredAt time.Time `json:"occurredAt"`
    Payload    json.RawMessage `json:"payload"`
}
```

## 3. 파티션 키와 순서 보장을 밝힙니다

순서는 파티션 단위로만 보장됩니다. 키 선택이 곧 순서 계약입니다.

```go
// Bad: 키 근거 없음 — 순서 보장 범위가 불명
producer.Send(key, value)

// Good
// Partition key = workloadID: guarantees ordered delivery of all events for a
// single workload (create → update → delete). Cross-workload order is NOT
// guaranteed. Do not switch to a random key — it breaks state reconstruction.
producer.Send(workloadID, value)
```

## 4. 전달 시맨틱과 멱등성을 문서화합니다

at-least-once면 컨슈머가 EventID로 멱등 처리해야 함을 명시합니다.

```go
// Good
// Delivery is at-least-once. handle MUST be idempotent on env.EventID:
// we upsert by EventID and drop replays, because a rebalance can redeliver
// uncommitted offsets.
func handle(env Envelope) error
```

## 5. DLQ, 컨슈머 그룹 가정을 남깁니다

재시도 소진 후 행선지와, 그룹 리밸런스 전제를 문서화합니다.

```go
// Good
// After 5 failed attempts the message goes to xpu.workload.dlq with the original
// EventID preserved for manual replay. Poison messages must never block the
// partition — we commit the offset after DLQ publish, not before.
const maxAttempts = 5

// This consumer group assumes a single logical reader per tenant partition set;
// scaling beyond partition count leaves consumers idle (Kafka assignment limit).
const consumerGroup = "xpu-workload-reconciler"
```
