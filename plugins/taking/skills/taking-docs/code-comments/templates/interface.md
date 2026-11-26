# interface 템플릿

인터페이스 doc은 **계약**을 적습니다: 사전/사후조건, 불변식, 누가 구현하는가, thread-safety. 특정 구현의 동작은 적지 않습니다(구현이 바뀌어도 계약은 유지돼야 합니다).

## 왜/언제

- **언제**: 여러 구현이 있거나 있을 인터페이스. 경계를 이루는 추상화.
- **왜**: 인터페이스는 구현자와 호출자 사이의 약속입니다. 구현 하나의 세부를 적으면 다른 구현이 그것을 어깁니다. 계약(무엇을 보장해야 하는가)만이 리팩터링을 견딥니다.
- **적을 것**: precondition(호출자 책임), postcondition(구현자 보장), 불변식, 에러 계약, thread-safety, 구현자에게 요구하는 것.

## 스켈레톤 (Go)

```go
// <Name> <이 추상화가 대표하는 역할>.
//
// Implementations must <구현자에게 요구하는 계약: 불변식, thread-safety>.
// <메서드 호출 순서 제약이 있으면 명시>.
type <Name> interface {
	// <Method> <postcondition: 무엇을 보장하는가>.
	// <precondition: 호출자가 지켜야 할 것>.
	// <에러 계약: 어떤 조건에서 어떤 에러>.
	<Method>(<params>) (<results>)
}
```

## 스켈레톤 (Java)

```java
/**
 * <역할>.
 *
 * <p>Implementations must be <thread-safety 계약> and must <불변식>.
 */
public interface <Name> {
    /**
     * <postcondition>.
     *
     * @param <p> <precondition>
     * @return <보장하는 반환 계약>
     * @throws <E> <에러 계약>
     */
    <R> <method>(<params>);
}
```

## Good example (Go)

```go
// Store persists cluster manifests keyed by (clusterID, revision).
//
// Implementations must be safe for concurrent use by multiple goroutines.
// Revisions are immutable once written: Put with an existing revision must
// return ErrRevisionExists rather than overwrite, so readers never observe a
// changed revision.
type Store interface {
	// Get returns the manifest at revision. It returns ErrNotFound when no
	// such revision exists and honors ctx cancellation. The returned slice
	// must not be retained by the implementation after Get returns.
	Get(ctx context.Context, clusterID string, revision int64) ([]byte, error)
}
```

## Good example (Java)

```java
/**
 * Resolves a tenant's effective quota from layered policy sources.
 *
 * <p>Implementations must be thread-safe. Resolution must be deterministic:
 * the same inputs yield the same quota within one policy generation, so
 * callers may cache results per generation.
 */
public interface QuotaResolver {
    /**
     * Returns the effective quota, never {@code null}; unknown tenants resolve
     * to the configured default quota rather than throwing.
     *
     * @param tenantId non-null tenant key
     * @return resolved quota, never {@code null}
     * @throws PolicyUnavailableException if no policy generation is loaded yet
     */
    Quota resolve(String tenantId);
}
```
