# good-java : 이미 모범적인 Java 파일

목표 상태(Java). Before가 이미 좋습니다 → Review는 대부분 "변경 없음" + nit 두 개 → After는 미세 개선만.

포인트: JavaDoc `@param`/`@return`/`@throws`, thread-safety 명시, 계약(멱등성) 문서화, WHY 주석만.

---

## 목차

- Before
- Review
  - Improve Code
  - Improve Naming
  - Remove
  - Rewrite
  - Add
  - Risks
- After

## Before

```java
/**
 * Publishes workload lifecycle events to the tenant-scoped Kafka topic.
 *
 * <p>Instances are thread-safe: the underlying producer is a single
 * {@link org.apache.kafka.clients.producer.KafkaProducer}, which the Kafka
 * client documents as safe to share across threads.
 */
public final class WorkloadEventPublisher {

    private final Producer<String, byte[]> producer;
    private final String topic;

    /**
     * Publishes one event keyed by {@code workloadId} so all events for a
     * single workload land on the same partition and preserve order.
     *
     * <p>Delivery is at-least-once; consumers must dedupe on {@code eventId}.
     *
     * @param workloadId partition key; must be non-blank
     * @param payload    serialized event body; the caller retains ownership
     * @return the broker-assigned offset once the write is acknowledged
     * @throws PublishException if the broker rejects the write or the ack times out
     */
    public long publish(String workloadId, byte[] payload) throws PublishException {
        var record = new ProducerRecord<>(topic, workloadId, payload);
        try {
            return producer.send(record).get().offset();
        } catch (ExecutionException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new PublishException("publish to " + topic + " failed", e);
        }
    }
}
```

## Review

클래스 JavaDoc이 thread-safety 근거를 남겼고, `publish`는 파티션 키 의미, **at-least-once 계약**, `@param`/`@return`/`@throws`를 모두 문서화했습니다. 대부분 변경 없음.

### Improve Code
- 변경 없음. `InterruptedException` 시 인터럽트 플래그를 복원하는 처리가 정확합니다.

### Improve Naming
- 변경 없음.

### Remove
- 제거 없음. 남은 주석은 모두 계약(키→파티션, at-least-once)을 설명합니다.

### Rewrite
- 클래스 JavaDoc의 thread-safety 문장에 "왜 공유해도 되는가"(Kafka 클라이언트 보장)가 이미 있어 좋습니다. `@link`가 문장을 길게 만드니 근거만 남기고 링크는 짧게. [nice]

### Add
- `payload`를 브로커가 그대로 저장한다는 점(전송 후 호출자가 수정하면 안 됨)은 미묘한 계약입니다. 한 줄 추가 검토. [nice]

### Risks
- `producer.send(...).get()`은 동기 블로킹입니다. 공개 계약("ack까지 블로킹")과 일치하므로 문제 아님. 다만 호출자가 이벤트 루프에서 부르면 병목입니다. JavaDoc이 이미 블로킹을 명시해 방어됨. [nice]

---

## After

```java
/**
 * Publishes workload lifecycle events to the tenant-scoped Kafka topic.
 *
 * <p>Instances are thread-safe: the underlying {@code KafkaProducer} is
 * documented as safe to share across threads.
 */
public final class WorkloadEventPublisher {

    private final Producer<String, byte[]> producer;
    private final String topic;

    /**
     * Publishes one event keyed by {@code workloadId} so all events for a
     * single workload land on the same partition and preserve order.
     *
     * <p>Delivery is at-least-once; consumers must dedupe on {@code eventId}.
     *
     * @param workloadId partition key; must be non-blank
     * @param payload    serialized event body; must not be mutated after this
     *                   call returns, as the client may buffer it for retries
     * @return the broker-assigned offset once the write is acknowledged
     * @throws PublishException if the broker rejects the write or the ack times out
     */
    public long publish(String workloadId, byte[] payload) throws PublishException {
        var record = new ProducerRecord<>(topic, workloadId, payload);
        try {
            return producer.send(record).get().offset();
        } catch (ExecutionException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new PublishException("publish to " + topic + " failed", e);
        }
    }
}
```
