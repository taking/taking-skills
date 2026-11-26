# javadoc 템플릿

공개 메서드, 클래스의 JavaDoc. `@param`/`@return`/`@throws`로 계약을 명시하고, nullability, thread-safety를 반드시 표기합니다. 구현 재진술은 쓰지 않습니다.

## 왜/언제

- **언제**: public, protected 메서드와 클래스에 항상.
- **왜**: 자바는 nullability와 thread-safety를 타입으로 강제하지 못합니다. 문서가 유일한 계약입니다.
- **관례**: 첫 문장은 요약(summary fragment)으로 마침표까지가 툴팁에 노출됩니다. 코드 심볼은 `{@code ...}`, 링크는 `{@link ...}`. `@throws`는 checked, unchecked 모두 계약이면 적습니다.

## 스켈레톤 (method)

```java
/**
 * <목적: 무엇을 보장하는가. 3인칭 현재형 한 문장 요약>.
 *
 * <추가 계약, 전제조건, 불변식. 필요 시 여러 문단>.
 *
 * @param <name> <유효 범위, 전제조건. null 허용 여부 명시>
 * @return <반환값 의미. null 반환 가능하면 반드시 명시. {@code Optional}이면 비었을 때 조건>
 * @throws <ExceptionType> <어떤 조건에서 던지는가>
 * @implNote <thread-safety, 부작용 등 구현 계약. 해당 없으면 생략>
 */
<modifiers> <ReturnType> <methodName>(<params>) {
```

## 스켈레톤 (class)

```java
/**
 * <클래스가 표현하는 개념, 책임>.
 *
 * <불변식. 생성 방법(생성자, 팩토리). 사용 제약>.
 *
 * <p>Thread-safety: <immutable | thread-safe | not thread-safe: 외부 동기화 필요>.
 */
public final class <ClassName> {
```

## Good example

```java
/**
 * Reserves {@code count} permits for {@code tenantId}, blocking until they are
 * available or the deadline elapses.
 *
 * <p>Reservation is atomic: either all {@code count} permits are granted or none
 * are, so a timeout leaves the tenant's quota untouched.
 *
 * @param tenantId non-null tenant key; unknown tenants are rejected, not created
 * @param count    number of permits, must be {@code > 0}
 * @param deadline absolute deadline, not a duration; must be in the future
 * @return {@code true} if all permits were granted, {@code false} on timeout
 * @throws IllegalArgumentException if {@code count <= 0}
 * @throws InterruptedException     if the calling thread is interrupted while waiting
 * @implNote Thread-safe; permits are tracked under a per-tenant lock.
 */
public boolean reserve(String tenantId, int count, Instant deadline)
        throws InterruptedException {
```
