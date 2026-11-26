# concurrency 템플릿

동시성 코드는 등장하는 순간 의도를 적습니다. 핵심 4가지: **락이 무엇을 보호하는가**, **goroutine/thread 소유권**, **락 순서**, **context 취소, happens-before**.

## 왜/언제

- **언제**: mutex, atomic, channel, goroutine, `sync.Once`(Go), `synchronized`, `volatile`, Lock, `Atomic*`, Executor(Java) 등장 시 필수.
- **왜**: 동시성 버그(race, deadlock)는 코드만 봐선 안 드러납니다. "이 락이 무엇을 보호하고 어떤 순서로 잡는가"가 없으면 다음 사람이 락 순서를 뒤집어 deadlock을 만듭니다.
- **적을 것**: 각 락이 지키는 필드, 누가 goroutine/thread를 시작, 종료하는가, 다중 락의 획득 순서, context 취소 전파, atomic으로 성립하는 happens-before.

## 스켈레톤 (Go)

```go
type <T> struct {
	mu <sync.Mutex>   // guards <이 락이 지키는 필드 목록>.
	<fields>
}

// <함수가 시작하는 goroutine의 수명, 종료 조건>.
// Lock order: <여러 락을 잡으면 항상 이 순서. deadlock 방지 근거>.
// Cancellation: <ctx 취소 시 goroutine이 어떻게 빠져나가는가>.
```

## 스켈레톤 (Java)

```java
/**
 * <불변식>.
 *
 * <p>Thread-safety: <전략>. {@code <lock>} guards <필드>.
 * Lock order: <다중 락 순서>.
 */
```

## Good example (Go)

```go
type Broker struct {
	mu   sync.Mutex          // guards subs and closed; not held during send.
	subs map[string]chan Msg // per-topic subscriber channel.
	inbox chan Msg           // inbound messages; dispatch reads these in its select.
	closed bool
}

// dispatch runs one goroutine per broker, started by NewBroker and stopped
// when Close cancels ctx. It reads subs under mu, then releases mu before
// sending on subscriber channels: holding mu across a blocking send would let
// a slow subscriber stall Subscribe/Unsubscribe (and, if a subscriber calls
// back into the broker, deadlock).
//
// Lock order: Broker.mu is a leaf. Never acquire another broker lock while
// holding it.
func (b *Broker) dispatch(ctx context.Context) {
	for {
		select {
		case <-ctx.Done(): // Close path: drain and exit, no further sends.
			return
		case m := <-b.inbox:
			b.mu.Lock()
			targets := b.subs[m.Topic] // snapshot the channel ref under lock.
			b.mu.Unlock()
			targets <- m // send without the lock held.
		}
	}
}
```

## Good example (Java)

```java
/**
 * Bounded connection pool. Invariant: {@code leased + idle.size() <= capacity}.
 *
 * <p>Thread-safety: guarded by {@code lock}; {@code notEmpty} signals waiters
 * when a connection is returned. Lock order: acquire {@code PoolManager.lock}
 * before any per-pool {@code lock}, never the reverse, to avoid deadlock
 * between resize and lease.
 */
final class ConnectionPool {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notEmpty = lock.newCondition();
    private int leased;             // guarded by lock
    private final Deque<Conn> idle; // guarded by lock

    /** Blocks until a connection is free or the thread is interrupted. */
    Conn lease() throws InterruptedException {
        lock.lock();
        try {
            while (idle.isEmpty() && leased >= capacity) {
                notEmpty.await(); // releases lock; re-checks predicate on wake.
            }
            leased++;
            return idle.isEmpty() ? open() : idle.pop();
        } finally {
            lock.unlock();
        }
    }
}
```
