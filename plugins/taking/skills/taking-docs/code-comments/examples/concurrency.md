# concurrency : 동시성 의도 문서화

동시성 프리미티브가 등장하면 WHY 필수: **무엇을 보호하는지, 소유권, 락 순서**. 코드는 무엇을 하는지만 보이고, 안전 근거는 안 보입니다.

---

## 목차

- Go : mutex / goroutine / context
  - Before
  - Review
  - After
- Java : synchronized / volatile / Atomic
  - Before
  - Review
  - After

## Go : mutex / goroutine / context

### Before

```go
type sessionPool struct {
	mu       sync.Mutex
	sessions map[string]*Session
	closing  chan struct{}
}

func (p *sessionPool) get(id string) *Session {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.sessions[id]
}

func (p *sessionPool) reap(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case <-time.After(reapInterval):
			p.mu.Lock()
			for id, s := range p.sessions {
				if s.idle() {
					delete(p.sessions, id)
				}
			}
			p.mu.Unlock()
		}
	}
}
```

### Review
**Add [must-fix]** : `mu`가 정확히 무엇을 보호하는지, `reap` goroutine의 수명을 누가 소유하는지가 문서화되지 않았습니다. 동시성 코드에서 이건 계약입니다. **Add [must-fix]** : `reap` 안에서 map을 순회하며 `delete` 하는데, 이게 안전한 건 같은 락을 잡고 있어서입니다. 이 불변식(모든 sessions 접근은 mu 아래)이 명시돼야 이후 수정자가 락 없는 접근을 추가하지 않습니다. **Add [should]** : `s.idle()`을 락 안에서 호출합니다: Session 내부 상태를 읽으므로 락 순서(pool.mu → session 내부)가 암묵적입니다. 역순 접근이 생기면 데드락 위험 → 순서를 적습니다. **Remove** : 없음(주석 자체가 없습니다).

### After

```go
type sessionPool struct {
	// mu guards sessions. All reads and writes of the map (and of any
	// Session reached through it) must hold mu. Lock order: pool.mu is
	// always acquired before a Session's own lock, never the reverse.
	mu       sync.Mutex
	sessions map[string]*Session
	closing  chan struct{}
}

func (p *sessionPool) get(id string) *Session {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.sessions[id]
}

// reap runs until ctx is cancelled; the caller owns its lifetime and must
// cancel ctx to stop it. Deleting during range is safe only because we hold
// mu for the whole sweep.
func (p *sessionPool) reap(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case <-time.After(reapInterval):
			p.mu.Lock()
			for id, s := range p.sessions {
				if s.idle() { // reads Session state under pool.mu, per lock order above
					delete(p.sessions, id)
				}
			}
			p.mu.Unlock()
		}
	}
}
```

---

## Java : synchronized / volatile / Atomic

### Before

```java
public final class ReconnectGate {
    private volatile boolean open = true;
    private final AtomicInteger failures = new AtomicInteger();
    private long openedAt;

    public boolean allow() {
        return open;
    }

    public synchronized void recordFailure() {
        if (failures.incrementAndGet() >= 5) {
            open = false;
            openedAt = System.nanoTime();
        }
    }
}
```

### Review
**Add [must-fix]** : `volatile open`과 `synchronized recordFailure`, `AtomicInteger failures`가 왜 이렇게 나뉘었는지 근거가 없습니다. `open`은 락 없이 읽히고(핫패스), 상태 전이는 `synchronized`로 직렬화한다는 설계 의도를 적어야 합니다. **Add [must-fix]** : `openedAt`은 `volatile`도 `synchronized` 밖 읽기도 없습니다: 오직 `synchronized` 안에서만 접근한다는 불변식이 명시돼야 다른 메서드가 락 없이 읽는 실수를 막습니다. **Improve Code [should]** : `failures`가 `AtomicInteger`인데 정작 전이는 `synchronized` 안입니다. 락 안에서만 증가시킨다면 plain `int`로 충분합니다(중복 동기화 제거). 다만 저자 의도(락 밖 관측 여지)를 모를 수 있어 주석으로 의도를 먼저 확정하도록 제안.

### After

```java
public final class ReconnectGate {
    // open is read on the hot path (allow) without locking, so it is volatile.
    // All *transitions* of open go through recordFailure under this monitor,
    // which serializes concurrent failures. openedAt is written and read only
    // while holding this monitor — never touch it without synchronization.
    private volatile boolean open = true;
    private int failures;
    private long openedAt;

    public boolean allow() {
        return open;
    }

    public synchronized void recordFailure() {
        // 5회 연속 실패면 순단이 아니라 지속 장애로 보고 게이트를 닫습니다
        if (++failures >= 5) {
            open = false;
            openedAt = System.nanoTime();
        }
    }
}
```
