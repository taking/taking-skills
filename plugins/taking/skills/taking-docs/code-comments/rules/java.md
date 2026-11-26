# java (Java 문화 규칙)

Effective Java, Google Java Style, Javadoc Guide 관례. 공개 API는 JavaDoc으로 계약을 명시합니다.

---

## 1. `@param`/`@return`/`@throws`로 계약을 적습니다

각 태그는 WHAT이 아니라 제약, 의미를 담습니다. checked, unchecked 예외 조건을 모두 문서화합니다.

```java
// Bad: 태그가 이름을 반복만 함
/** Sends the event. @param event the event @return the result */
Ack send(Event event);

// Good: 계약을 담은 태그
/**
 * Publishes {@code event} to the tenant's Kafka topic.
 *
 * @param event non-null; {@link Event#id()} is used as the idempotency key
 * @return the broker ack; never null
 * @throws TunnelClosedException if the tunnel closed concurrently (retryable)
 * @throws IllegalArgumentException if {@code event.id()} is blank (unchecked, programming error)
 */
Ack send(Event event);
```

## 2. nullability 계약을 명시합니다

`@Nullable`/`@NonNull`로 null 허용 여부를 코드에 박습니다. 주석으로만 말하지 않습니다.

```java
// Bad: null이 오는지 알 수 없습니다
Tunnel lookup(String clusterId);

// Good: 반환이 null일 수 있음을 타입 수준에서 계약화
/** @return the open tunnel, or {@code null} if none is registered for the cluster */
@Nullable
Tunnel lookup(@NonNull String clusterId);
```

## 3. `{@code}`, `{@link}`를 씁니다

식별자, 리터럴은 `{@code}`, 참조는 `{@link}`. 평문으로 쓰면 렌더링이 깨지고 오타 추적이 안 됩니다.

```java
// Bad: // returns true if state is RUNNING
// Good:
/** @return {@code true} if the reconciler observed {@link Phase#RUNNING} */
boolean isReady();
```

## 4. 클래스에 thread-safety를 선언합니다

스레드 안전성은 클래스 수준 계약입니다. `@ThreadSafe`/`@NotThreadSafe` 의도와 `@GuardedBy`로 무엇이 무엇을 지키는지 밝힙니다.

```java
// Bad: 동시성 안전 여부 불명 — 호출자가 락을 걸어야 하나?
class TunnelRegistry { ... }

// Good: 계약과 가드 명시
/**
 * Thread-safe. All mutations go through {@code lock}; reads of {@link #tunnels}
 * outside the lock are forbidden because the map is rehashed on register.
 */
@ThreadSafe
class TunnelRegistry {
    private final Object lock = new Object();

    @GuardedBy("lock")
    private final Map<String, Tunnel> tunnels = new HashMap<>();
}
```

## 5. 필드 불변식을 문서화합니다

필드가 지켜야 하는 조건(비음수, 정렬, 상호 배타)을 선언 옆에 남깁니다.

```java
// Bad
private long offset;

// Good: 불변식이 코드로 드러나지 않으므로 남깁니다
/** Monotonically increasing; never rewound — consumers rely on this for dedup. */
private long offset;
```

## 6. unchecked 예외도 문서화합니다

Effective Java: 던질 수 있는 unchecked 예외도 `@throws`로 밝혀 호출자가 사전 검증하게 합니다. 다만 시그니처의 `throws`에는 넣지 않습니다.

```java
// Good
/**
 * @throws IllegalStateException if called after {@link #close()} — lifecycle violation
 */
void publish(Record r);
```
