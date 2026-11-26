# style-guide (정본 규칙)

코드 주석, API 문서 리뷰의 정본 규칙입니다. 여러 레퍼런스(Effective Go, Go Code Review Comments, Go Doc Comments, Uber/Google Go Style, Effective Java, Google Java Style, Javadoc Guide, A Philosophy of Software Design, Clean Code, Refactoring, Kubernetes/KEP conventions)에서 반복해 나타나는 원칙을 종합했습니다. 충돌 시 **장기 유지보수성, 가독성, 정확성, 명시적 설계 의도**를 우선합니다.

원칙 순위 : **정확 > 명확 > 의도 표현 > 스타일 취향.**

---

## 목차

- 1. 코드를 먼저 고칩니다
- 2. WHY, never WHAT
- 3. 리팩터링을 견딥니다
- 4. 중복 주석 삭제
- 5. 이름 > 주석
- 6. 공개 API는 문서화 필수
- 7. 내부/헬퍼는 최소화
- 8. 계약(Contract)
- 9. 보안 가정
- 10. 동시성
- 11. 성능 최적화
- 12. Workaround
- 13. TODO는 owner/issue 포함
- 14. 언어 정책 (한국어 산문, 영어 용어)
- 15. AI투 일반 동사 지양
- 16. 리뷰 순서와 출력
- 17. 고위험 코드
- 18. 아키텍처(패키지, 모듈) 주석
- 19. DRY
- 20. 미래 유지보수자 우선
- 21. Delete-first
- 22. 주석 품질 체크리스트
- 23. 짧게, 그리고 이 코드만 설명합니다
- 24. WHY는 설계 서사가 아닙니다
- 25. 종결 형태 : 존댓말 기본, 짧은 사실은 명사형

## A. 우선순위와 태도

### 1. 코드를 먼저 고칩니다
불명확한 코드는 주석으로 설명하지 말고 이름, 구조를 고칩니다.

```go
// Bad: 주석으로 변명
// t is the deadline in seconds
t := 30
// Good: 이름이 설명
deadlineSeconds := 30
```

### 5. 이름 > 주석
이름이 나쁘면 주석을 붙이지 말고 이름을 바꿉니다. `d`, `tmp`, `data2`, `process()`는 주석의 신호가 아니라 개명의 신호입니다.

### 21. Delete-first
주석마다 **"지우면 다음 사람이 코드를 잘못 고치나?"** 묻습니다. 아니오 → 삭제.

`"이해가 어려워지나"`로 재지 않습니다. 그 기준은 통과 범위가 넓어, 한 결정마다 설명 문단이 붙습니다.

### 19. DRY
같은 사실을 여러 주석에 반복하지 않습니다. 한 곳(가까운 선언, 패키지 doc)에 둡니다.

### 20. 미래 유지보수자 우선
"지금 내가 아는 것"이 아니라 "6개월 뒤 처음 보는 사람"을 위해 씁니다.

---

### 23. 짧게, 그리고 이 코드만 설명합니다

- 대부분의 주석은 **1–3줄**에 담습니다. 이 한도를 넘어도 되는 건 architecture, security, protocol contract, concurrency 설명뿐입니다.
- 5줄을 넘겨야 하면 설명을 **문서로 옮기고**, 주석엔 짧은 요약 + 참조만 남깁니다.
- 한 번 읽고 이해되어야 합니다.
- **문법을 해설하지 않습니다.** `x += 1 // x를 1 늘린다` 같은 줄은 지웁니다.
- 한 줄은 **80자 이내**로 끊습니다. 다만 줄바꿈이 불가능한 기계 지시자(kubebuilder 마커 `+kubebuilder:...`, `//nolint:...`, struct tag, Javadoc `@param`/`@throws` 연속 행)는 예외입니다.
- **소스 주석은 이 코드를 설명합니다. 기술 자체는 문서가 설명합니다.** 소스에서 분산 시스템을 가르치지 않습니다.

## B. 무엇을 쓰나

### 2. WHY, never WHAT
설명할 것 : 의도(intent), 이유(why), 제약(constraint), 가정(assumption), 불변식(invariant), 트레이드오프, 부작용, 호환성, 보안 가정. WHAT은 코드가 말합니다.

```go
// Bad: WHAT (코드 재진술)
// increment retry
retry++
// Good: WHY (지우면 잃는 정보)
// 5회까지만: 그 이상은 브로커 장애가 아니라 설정 오류일 가능성이 높습니다
if retry++; retry > 5 { ... }
```

### 24. WHY는 설계 서사가 아닙니다

WHY를 적으라는 말은 **결정 과정을 서술하라는 뜻이 아닙니다.** 소스에는 이 코드를 잘못 고치게 막는 사실만 남기고, 결정의 배경은 문서, 커밋, ADR로 보냅니다.

| 소스에 쓰지 않을 것 | 갈 곳 |
| --- | --- |
| 대안 비교, 채택 근거 | 설계 문서, ADR |
| 걷어낸 구현의 회고("예전에는 ~였다") | 커밋 메시지 |
| UX, 제품 근거 | 화면 시나리오, 기획 문서 |
| 값을 그렇게 고른 이야기 | 상수 이름으로 드러내거나 생략 |
| 저자 회고("~로 옮겼다", "실제로 겪었다", "만들어 봤다") | 지웁니다 |
| 사실 뒤에 습관처럼 붙는 정당화(`~므로 ~한다`) | 지웁니다 |

같은 사실도 **잘못 고치는 것을 막는 형태**로만 남깁니다.

```ts
// Bad: 결정 서사 5줄. 지워도 코드를 잘못 고치지 않습니다.
// 탭과 자원 종류를 주소에 둔다. 목록이 detailId, view를 주소에 두는 것과 같은 이유로,
// 새로고침하면 보던 탭에 그대로 있어야 하고 특정 탭 링크를 건넬 수 있어야 한다.
// replace로 바꾼다. 탭을 넘길 때마다 이력이 쌓이면 뒤로가기가 목록이 아니라 앞 탭으로 간다.
setSearchParams(next, { replace: true })

// Good: 지우면 push로 "정리"하고 뒤로가기가 깨집니다.
// push면 뒤로가기가 목록이 아니라 앞 탭으로 갑니다.
setSearchParams(next, { replace: true })
```

### 3. 리팩터링을 견딥니다
구현 세부를 설명하는 주석은 구현이 바뀌면 거짓이 됩니다. 의미, 계약을 설명해 구현이 바뀌어도 유지되게 씁니다.

```java
// Bad: 구현 설명(깨지기 쉬움)
// loop over the list and sum
// Good: 계약(리팩터링 후에도 유효)
// 합계는 오버플로 시 saturating 처리합니다(호출자가 clamp 안 함)
```

### 4. 중복 주석 삭제
코드를 읽으면 아는 주석은 지웁니다.

```go
return user   // Bad: // Return user.
```

---

## C. 공개/내부 경계

### 6. 공개 API는 문서화 필수
Go는 GoDoc, Java는 JavaDoc으로 씁니다. 포함 : 목적, 파라미터, 반환값, 에러 조건, 부작용, 동시성 고려, 호환성. 언어별 관례는 `rules/go.md`, `rules/java.md`에 있습니다.

### 7. 내부/헬퍼는 최소화
private, helper는 Why, 제약, 불변식만 적습니다. 자명한 헬퍼엔 주석을 달지 않습니다.

### 18. 아키텍처(패키지, 모듈) 주석
패키지, 모듈은 목적과 경계를 설명합니다.

```go
// Good
// Package tunnel implements the reverse gRPC tunnel.
// It intentionally does not depend on client-go: the tunnel moves bytes and
// must not parse apiserver responses.
```

---

## D. 반드시 문서화 (계약, 고위험)

### 8. 계약(Contract)
wire protocol, header, label, annotation, eventType, Kafka topic, CRD field, feature flag, env var, serialization format, API 호환성. 도메인별 예는 `rules/{grpc,protobuf,kubernetes,kafka}.md`에 있습니다. 계약, 불변식, 보장을 서술할 때 요구 수준은 영어 RFC 2119 키워드(MUST/SHOULD/MAY)로 고정합니다(§14, [../reference/requirement-levels.md](../reference/requirement-levels.md)).

### 9. 보안 가정
authn, authz, trust boundary, 입력 검증(validation), sanitization, 권한 가정, 민감 데이터 취급.

### 10. 동시성
등장 시 의도 필수입니다. Go : goroutine, channel, select, mutex, RWMutex, atomic, context 취소, `sync.Once`, `sync.Pool`. Java : `synchronized`, `volatile`, Lock, `Atomic*`, ThreadLocal, Executor, CompletableFuture, ForkJoinPool. "무엇을 보호하는지, 락 순서, 누가 소유하는지"를 적습니다.

### 11. 성능 최적화
allocation 감소, 객체 재사용, pooling, batching, caching, zero-copy, lazy init는 Why(측정 근거, 제약)를 적습니다. 최적화가 아니면 적지 않습니다.

### 12. Workaround
임시 우회는 이유와 제거 조건을 남기고, 가능하면 이슈 ID(GitHub/Jira/Bug)를 포함합니다.

### 17. 고위험 코드
`unsafe`, `reflect`, `panic/recover`(Go), Reflection, Unsafe(Java) 등은 왜 필요한지와 안전 근거를 반드시 설명합니다.

---

## E. 문체, 형식

### 13. TODO는 owner/issue 포함
허용 : `TODO(team-platform):`, `TODO(alice):`, `TODO(#123):`, `TODO(GH-321):`. 금지 : bare `TODO:`, `FIXME:`. (기계적 규칙 → lint로 강제 가능)

### 14. 언어 정책 (한국어 산문, 영어 용어)
주 유지보수자가 한국 개발자이므로 주석 산문은 **한국어**로 씁니다. 청중은 **유능한 엔지니어이나 분산 시스템, Kubernetes 내부 전문가는 아닙니다.** 가장 똑똑한 개발자가 아니라 **다음 개발자**를 위해 씁니다.

- **정착된 기술 용어는 영어로 둡니다.** Cluster, Namespace, Pod, Deployment, Controller, Reconciler, CRD, Webhook, Kafka Topic, Consumer Group, Offset, Context, Goroutine, Mutex, Channel, Leader Election, Sidecar 등. 널리 통용되는 용어는 억지로 번역하지 않습니다(명확한 한국어 정착어가 있을 때만 번역).
- **한 문장을 한, 영으로 어정쩡하게 섞거나** `단어(Word)` 식 이중표기를 남발하지 않습니다. 기본은 "산문=한국어, 용어=영어"입니다.
- **계약, wire, 공개 API 주석은 예외입니다.** 요구 수준은 영어 RFC 2119 키워드(MUST, MUST NOT, SHOULD, MAY)를 그대로 쓰고, 계약 산문도 영어를 허용합니다(소스 주석이라 굵게나 표는 쓰지 않습니다). 구현 WHY 산문은 한국어로 씁니다. 정본은 [../reference/requirement-levels.md](../reference/requirement-levels.md).
- **의미를 가리는 개념 용어는 첫 등장에 짧은 포인터(용어 + 반 줄 이하)만 붙이고, 개념 자체 설명은 문서로 미룹니다**(§23). 흔한 용어(Pod, Context)는 설명하지 않습니다.

```go
// Bad: 개념 용어를 던지기만 함 — DS 비전문가는 못 읽는다
// 이 핸들러는 멱등성을 보장한다.

// Bad: 매번 긴 평문으로 교체 — 장황하고 정밀 용어를 잃는다
// 같은 요청이 여러 번 들어와도 결과가 한 번 실행한 것과 같게 처리한다.

// Good: 짧은 포인터만, 개념 강의는 docs로
// 멱등(idempotent). Kafka 재전송(at-least-once)이 있어도 안전합니다.
```

```go
// Bad: 정착 용어를 억지 번역
// 꼬투리(Sidecar) 컨테이너가 부하 분산기를 통해 파드에 붙는다.
// Good: 산문은 한국어, 정착 용어는 영어
// Sidecar 컨테이너가 같은 Pod에서 함께 뜹니다.
```

### 15. AI투 일반 동사 지양
`Handle`, `Process`, `Manage`, `Support`, `Perform`, `Execute`, `Create`, `Initialize`, `Set`, `Update`처럼 뭉뚱그린 동사 대신 구체적 의도를 씁니다.

```go
// Bad: // Handle the request.
// Good: // 중복 eventId면 조용히 스킵합니다(at-least-once 재전송 방어)
```

---

### 25. 종결 형태 : 존댓말 기본, 짧은 사실은 명사형

기본 톤은 존댓말(`~합니다`)입니다(저장소 관례 우선, 상위 `SKILL.md` §2). 단 **한 가지 짧은 사실**은 종결어미 없이 명사형으로 끊어도 됩니다. 종결형 중 `~합니다`가 가장 길어, 억지로 붙이면 문장이 되고 문장이 되면 정당화 절이 딸려옵니다. 짧은 사실에는 명사형이 그 꼬리를 막습니다.

- **존댓말 `~합니다`** : 동작, 판단을 설명할 때. 저장소가 다른 관례(평서체 `~한다`)로 통일돼 있으면 그것을 우선합니다(규칙 1).
- **명사형** : 짧은 사실은 체언으로 끊습니다(`~ 필터링`, `~ 상한`, `~ 없음`, `~ 기준`). 존댓말과 동급 선택지입니다.
- 한 블록에서 같은 종결이 3줄 연속되지 않게 합니다.

```python
# Bad: 문법 해설(코드 재진술)
# False를 반환하여 접근을 차단합니다.

# Good: 존댓말. 코드에 없는 근거와 예외만 적습니다
# 청소년보호법 기준 만 19세 미만을 거릅니다 (가족 계정 예외 없음)

# Good: 짧은 사실은 명사형으로 끊어도 됩니다
# 청소년보호법 기준 만 19세 미만 필터링 (가족 계정 예외 없음)
```

```ts
// Bad: 사실 뒤에 이유 절이 따라붙어 늘어졌습니다
// 검색어는 주소에 넣지 않습니다. 글자마다 이력이 쌓입니다.

// Good: 명사형으로 끊으면 정당화가 붙을 자리가 없음
// 검색어는 주소에서 제외 (글자마다 이력이 쌓임)
```

## F. 리뷰 진행 (워크플로)

### 16. 리뷰 순서와 출력
순서 : Improve Code → Improve Naming → Remove → Rewrite → Add. 출력 6섹션(+심각도) :

```markdown
### Improve Code      # [must-fix]/[should]/[nice]
### Improve Naming
### Remove
### Rewrite
### Add
### Risks
```

- **심각도** : `must-fix`(정확성, 계약, 보안, 동시성 오류/누락), `should`(가독성, 유지보수), `nice`(취향).
- **Advisory-first** : 리포트가 기본입니다. 코드 반영은 승인 후.
- **Minimal-diff** : 제안만, 무단 전면 재작성 금지. 저자 스타일 존중.

### 22. 주석 품질 체크리스트
추가, 유지할 주석은 아래 중 최소 하나를 만족해야 합니다 : WHY, 의도, 제약, 트레이드오프, 불변식, 계약, 보안, 동시성, 성능, (그리고) 리팩터링을 견디는가. 전체 목록은 `checklist.md`에 있습니다.
