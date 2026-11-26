# bad-comments : 최악 패턴 카탈로그

작은 Before → Review → After 쌍 모음. 각 쌍은 흔한 안티패턴 하나를 다룹니다: WHAT 재진술, 주석처리된 코드, stale 주석, bare TODO, AI투 동사, 언어 혼용.

---

## 목차

- 1. WHAT 재진술 (코드 번역)
- 2. 주석처리된 코드
- 3. Stale 주석 (구현과 어긋남)
- 4. Bare TODO (owner, issue 없음)
- 5. AI투 뭉뚱그린 동사 ("Handle"/"Process")
- 6. 언어 혼용 (한, 영 섞임)
- 7. 설계 서사 (결정 과정을 소스에 서술)
- 8. 걷어낸 구현의 회고
- 9. 문법 해설

## 1. WHAT 재진술 (코드 번역)

### Before

```go
// increment the retry counter
retry++
// if retry is greater than 5, return an error
if retry > 5 {
	return errTooManyRetries
}
```

### Review
**Remove [should]** : 두 주석 모두 코드를 그대로 번역합니다. 지워도 정보 손실 없음(delete-first 탈락). 임계값 `5`의 근거만 WHY로 남길 가치가 있습니다.

### After

```go
// 5회 초과면 브로커 장애가 아니라 설정 오류일 가능성이 높다 → 재시도 중단
if retry++; retry > 5 {
	return errTooManyRetries
}
```

---

## 2. 주석처리된 코드

### Before

```java
public void reconnect() {
    // backoff = 1000;
    // backoff = backoff * 2;
    long backoff = nextBackoffMillis();
    sleep(backoff);
}
```

### Review
**Remove [must-fix]** : 주석처리된 코드는 잡음이자 거짓 이력입니다. 되살릴 근거는 git이 가집니다. 삭제합니다.

### After

```java
public void reconnect() {
    long backoff = nextBackoffMillis();
    sleep(backoff);
}
```

---

## 3. Stale 주석 (구현과 어긋남)

### Before

```go
// retries up to 3 times with a fixed 1s delay
func dialWithRetry(ctx context.Context) (*Session, error) {
	return retry(ctx, expBackoff(maxAttempts)) // maxAttempts=8, exponential
}
```

### Review
**Rewrite [must-fix]** : 주석은 "3회, 고정 1s"라는데 코드는 "8회, 지수 백오프"입니다. Stale 주석은 없느니만 못합니다. 구현 세부(횟수, 지연)는 상수가 말하게 하고, 주석은 리팩터링을 견디는 의미만 남깁니다.

### After

```go
// 지수 백오프로 재시도: 여러 agent 동시 재접속 시 apiserver 과부하를 막습니다
func dialWithRetry(ctx context.Context) (*Session, error) {
	return retry(ctx, expBackoff(maxAttempts))
}
```

---

## 4. Bare TODO (owner, issue 없음)

### Before

```go
// TODO: fix this later
resourceVersion := ""
```

### Review
**Rewrite [should]** : owner도 이슈도 없는 TODO는 영원히 남습니다. 무엇을, 왜, 언제 제거할지와 이슈 ID를 넣습니다. (형식 강제는 lint로도 가능.)

### After

```go
// TODO(#412): watch 재수립 시 resourceVersion 유실 — informer 도입 후 제거
resourceVersion := ""
```

---

## 5. AI투 뭉뚱그린 동사 ("Handle"/"Process")

### Before

```go
// Handle the event.
func (c *Consumer) Handle(e Event) error { ... }

// Process the message.
func process(msg []byte) { ... }
```

### Review
**Remove + Improve Naming [should]** : `Handle the event`는 함수명 재진술이라 삭제. `process`는 이름 자체가 뭉뚱그린 동사입니다(개명 신호). 주석 대신 이름을 구체화합니다.

### After

```go
// 중복 eventId면 조용히 스킵합니다(at-least-once 재전송 방어)
func (c *Consumer) Consume(e Event) error { ... }

func decodeFrame(msg []byte) { ... }
```

---

## 6. 언어 혼용 (한, 영 섞임)

### Before

```java
// reconnect를 exponential backoff로 retry하고 실패 시 circuit을 open
private void onDisconnect() { ... }
```

### Review
**Rewrite [nice]** : 한 주석에 한국어, 영어를 섞으면 가독성이 떨어집니다. 한국어로 쓰고 용어는 괄호로 참조합니다.

### After

```java
// 재접속(reconnect)은 지수 백오프로 재시도하고, 실패가 이어지면 서킷을 엽니다
private void onDisconnect() { ... }
```

---

## 7. 설계 서사 (결정 과정을 소스에 서술)

### Before

```ts
/*
 * 탭과 자원 종류를 주소에 둡니다. 목록이 `detailId`, `view`를 주소에 두는 것과 같은 이유로,
 * 새로고침하면 보던 탭에 그대로 있어야 하고 특정 탭 링크를 건넬 수 있어야 합니다.
 *
 * `replace`로 바꿉니다. 탭을 넘길 때마다 이력이 쌓이면 뒤로가기가 목록이 아니라 앞 탭으로 갑니다.
 */
const [searchParams, setSearchParams] = useSearchParams()
```

### Review
**Remove [should]** : 주소에 둔다는 사실은 `useSearchParams`가 말합니다. 다섯 줄 중 지웠을 때 코드를 잘못 고치게 만드는 것은 `replace` 한 가지뿐입니다. 채택 근거는 설계 문서로 보냅니다.

### After

```ts
const [searchParams, setSearchParams] = useSearchParams()
// ...
// push면 뒤로가기가 목록이 아니라 앞 탭으로 갑니다.
setSearchParams(next, { replace: true })
```

---

## 8. 걷어낸 구현의 회고

### Before

```ts
/**
 * YAML 편집기. CodeMirror 6을 씁니다.
 *
 * 직접 만든 판(색칠한 판 + 투명 textarea 겹치기)을 걷어냈습니다. 두 겹의 글자 배치가 1px만
 * 어긋나도 커서가 밀렸고 Safari에서 끝까지 맞지 않았습니다.
 */
```

### Review
**Remove [should]** : 지금 없는 구현의 이야기입니다. 다음 사람이 이 코드를 고칠 때 쓰지 않습니다. git 이력과 커밋 메시지가 그 기록을 가집니다.

### After

```ts
/**
 * YAML 편집기. CodeMirror 6을 씁니다.
 *
 * `contenteditable` div로 그려서 globals.css의 `input, textarea` 강제 규칙에 잡히지 않습니다.
 */
```

---

## 9. 문법 해설

### Before

```python
def check_age(age):
    # 만약 나이가 19세 미만이라면
    if age < 19:
        # False를 반환하여 접근을 차단합니다.
        return False
    return True
```

### Review
**Remove + Rewrite [must-fix]** : 조건문의 동작은 코드에 있습니다. 코드에 없는 것은 `19`의 근거와 예외 유무입니다.

이 주석의 결함은 **문법 해설**입니다(`만약 나이가 19세 미만이라면`, `False를 반환하여 접근을 차단합니다`는 코드 재진술). After는 코드에 없는 WHY만 남깁니다. 짧은 사실이라 명사형으로 끊었습니다. 존댓말로 써도 되지만, 짧은 사실에는 명사형이 정당화 절을 막습니다(규칙 25).

### After

```python
def check_age(age):
    # 청소년보호법 기준 만 19세 미만 필터링 (가족 계정 예외 없음)
    if age < 19:
        return False
    return True
```
