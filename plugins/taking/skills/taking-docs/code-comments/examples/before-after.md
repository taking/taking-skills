# before-after : 이름, 구조가 주석을 없앱니다 (핵심 철학)

주석을 **추가**하기 전에 코드와 이름을 고칩니다. 아래 4개 쌍은 모두 리네이밍/구조 개선만으로 원래 필요하던 주석이 사라지는 경우입니다. 남는 주석은 코드가 표현 못 하는 WHY(계약, 제약)뿐입니다.

---

## 목차

- 1. 이름이 단위를 말하면 주석이 사라집니다
  - Before
  - Review
  - After
- 2. 조건을 이름 있는 함수로 뽑으면 설명 주석이 사라집니다
  - Before
  - Review
  - After
- 3. 매직 넘버를 이름 있는 상수로 (주석 대신 상수)
  - Before
  - Review
  - After
- 4. 단계 주석을 이름 있는 단계로 (주석이 곧 함수명)
  - Before
  - Review
  - After

## 1. 이름이 단위를 말하면 주석이 사라집니다

### Before

```go
// t is the timeout in seconds
// d is the delay before first retry in milliseconds
func newDialer(t int, d int) *Dialer {
	// convert to durations
	return &Dialer{
		timeout: time.Duration(t) * time.Second,
		delay:   time.Duration(d) * time.Millisecond,
	}
}
```

### Review
**Improve Naming [should]** : `t`, `d`는 개명 신호입니다. 단위를 이름에 넣으면 세 개의 주석(`t is...`, `d is...`, `convert to durations`)이 전부 불필요해집니다. **Improve Code [nice]** : 애초에 `time.Duration`을 받으면 변환 자체가 사라집니다. 다만 공개 시그니처 변경은 호출부 파급이 있어 minimal-diff 차원에서 이름 개선만 먼저 제안합니다. **Remove [should]** : 위 개선 후 세 주석 모두 삭제.

### After

```go
func newDialer(timeout time.Duration, firstRetryDelay time.Duration) *Dialer {
	return &Dialer{
		timeout: timeout,
		delay:   firstRetryDelay,
	}
}
```

---

## 2. 조건을 이름 있는 함수로 뽑으면 설명 주석이 사라집니다

### Before

```go
func (c *Consumer) shouldAck(e Event) bool {
	// ack only if the event is newer than what we've already committed,
	// and it belongs to a tenant we're still subscribed to, and it isn't
	// a heartbeat frame
	return e.Seq > c.committedSeq &&
		c.subscriptions[e.Tenant] &&
		e.Kind != KindHeartbeat
}
```

### Review
**Improve Code [should]** : 긴 불리언 식에 서술 주석을 다는 대신, 각 조건을 이름 있는 술어로 뽑으면 코드가 곧 문장이 됩니다. 주석이 코드와 어긋날 위험(stale)도 사라집니다. **Remove [should]** : 술어 추출 후 3줄 주석 삭제.

### After

```go
func (c *Consumer) shouldAck(e Event) bool {
	return c.isNewerThanCommitted(e) &&
		c.isSubscribed(e.Tenant) &&
		!e.isHeartbeat()
}

func (c *Consumer) isNewerThanCommitted(e Event) bool { return e.Seq > c.committedSeq }
func (c *Consumer) isSubscribed(tenant string) bool   { return c.subscriptions[tenant] }
func (e Event) isHeartbeat() bool                     { return e.Kind == KindHeartbeat }
```

---

## 3. 매직 넘버를 이름 있는 상수로 (주석 대신 상수)

### Before

```java
public boolean isStale(Instant lastSeen) {
    // an agent is considered dead after 90 seconds without a heartbeat
    // (3 missed heartbeats at the 30s interval)
    return Duration.between(lastSeen, Instant.now()).getSeconds() > 90;
}
```

### Review
**Improve Naming / Improve Code [should]** : 매직 넘버 `90`에 설명 주석을 다는 대신 유래가 드러나는 상수로 만듭니다. "3 missed heartbeats × 30s"라는 계산 근거는 코드로 표현 가능합니다. **Rewrite [nice]** : 상수로 옮기고 나면, 남길 주석은 "왜 3회인가"라는 정책 근거 한 줄뿐입니다.

### After

```java
private static final Duration HEARTBEAT_INTERVAL = Duration.ofSeconds(30);
// 3회 연속 누락이면 네트워크 순단이 아니라 agent 다운으로 판정합니다
private static final Duration LIVENESS_TIMEOUT = HEARTBEAT_INTERVAL.multipliedBy(3);

public boolean isStale(Instant lastSeen) {
    return Duration.between(lastSeen, Instant.now()).compareTo(LIVENESS_TIMEOUT) > 0;
}
```

---

## 4. 단계 주석을 이름 있는 단계로 (주석이 곧 함수명)

### Before

```go
func (r *Reconciler) reconcile(ctx context.Context, w *Workload) error {
	// step 1: make sure the namespace exists
	if err := r.ensureNamespace(ctx, w); err != nil {
		return err
	}
	// step 2: create or update the deployment
	d := buildDeployment(w)
	if err := r.apply(ctx, d); err != nil {
		return err
	}
	// step 3: write status back
	w.Status.Phase = PhaseRunning
	return r.updateStatus(ctx, w)
}
```

### Review
**Remove [should]** : `step N: ...` 주석은 호출하는 함수명이 이미 말합니다(`ensureNamespace`, `apply`, `updateStatus`). 번호 매기기는 유지보수 시 어긋나기 쉽습니다. 삭제. **Add [must-fix]** : 대신 코드가 표현 못 하는 계약 하나를 문서화합니다: 이 순서가 **멱등**해야 한다는 것(reconcile은 여러 번 호출됩니다). 이건 리네이밍으로 안 드러납니다.

### After

```go
// reconcile은 멱등합니다: apiserver가 같은 Workload로 여러 번 호출해도
// 최종 상태가 같아야 합니다. 각 단계는 create-or-update만 하고 삭제하지 않습니다.
func (r *Reconciler) reconcile(ctx context.Context, w *Workload) error {
	if err := r.ensureNamespace(ctx, w); err != nil {
		return err
	}
	if err := r.apply(ctx, buildDeployment(w)); err != nil {
		return err
	}
	w.Status.Phase = PhaseRunning
	return r.updateStatus(ctx, w)
}
```
