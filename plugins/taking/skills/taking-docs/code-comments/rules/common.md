# common (언어 무관 규칙)

언어, 도메인을 가리지 않는 주석 규칙. 충돌 시 `style-guide.md`의 우선순위를 따릅니다.

---

## 1. Delete-first

주석마다 **"지우면 다음 사람이 코드를 잘못 고치나?"** 묻습니다. 아니오면 삭제합니다. 코드가 이미 말하는 것은 잡음입니다.

`"이해가 어려워지나"`로 재면 통과 범위가 넓어 한 결정마다 설명 문단이 붙습니다.

WHY를 적으라는 말은 결정 과정을 서술하라는 뜻이 아닙니다. 대안 비교, 채택 근거, 걷어낸 구현의 회고, UX 근거, 저자 회고는 문서, 커밋, ADR로 보냅니다(style-guide 규칙 24).

```go
// Bad: 코드를 그대로 번역
// increment the counter by one
counter++

// Good: 주석 없음 — 코드가 자명합니다
counter++
```

## 2. WHY, never WHAT

무엇을 하는지는 코드가 말합니다. 왜 그렇게 했는지(의도, 제약, 트레이드오프)만 남깁니다.

```go
// Bad: WHAT
// sleep for 500ms
time.Sleep(500 * time.Millisecond)

// Good: WHY (지우면 잃는 정보)
// 재접속 폭주 방지: 여러 agent가 동시에 터널을 재수립하면 apiserver가 밀립니다
time.Sleep(reconnectJitter())
```

## 3. 리팩터링을 견딘다

구현 세부가 아니라 의미, 계약을 적습니다. 구현이 바뀌어도 참이어야 합니다.

```go
// Bad: 구현 설명 — 자료구조 바꾸면 거짓
// linearly scan the slice to find the node

// Good: 계약 — 구현이 바뀌어도 유효
// 반환 노드는 Ready 상태만: 호출자가 상태를 재확인하지 않아도 됩니다
```

## 4. DRY : 사실은 한 곳에

같은 사실을 여러 주석에 반복하지 않습니다. 가장 가까운 선언 한 곳에 둡니다.

```go
// Bad: 세 함수마다 "topic은 tenant별로 분리"를 반복

// Good: topic 상수 선언 위 한 곳에만 근거를 둡니다
// tenant별 토픽 분리: cross-tenant 소비를 브로커 ACL로 차단하기 위함
const workloadTopicPrefix = "xpu.workload."
```

## 5. 언어 정책 (한국어 산문, 영어 용어)

산문은 한국어, 정착된 기술 용어는 영어(Cluster, Pod, CRD, Context, Goroutine, Kafka Topic 등). 억지 번역, `단어(Word)` 이중표기를 남발하지 않습니다. 의미를 가리는 개념(멱등, 수렴, 순단)은 첫 등장에 짧은 포인터만 붙이고 개념 설명은 문서로 미룹니다. 주석은 1–3줄로 짧게(예외: architecture, security, protocol, concurrency), 5줄↑이면 문서로 옮기고 요약+참조만 남깁니다. 소스는 이 코드를, 문서는 기술을 설명합니다. 청중은 유능하나 분산/K8s 전문가는 아니며, 다음 개발자를 위해 씁니다. 상세는 `style-guide.md §14, §23`.

```go
// Bad: 개념을 소스에서 강의함
// 수렴(converge): 시간이 지나면 모든 노드가 같은 상태를 갖습니다. Raft에서는 ...
// Good: 짧은 포인터, 개념은 docs로
// 수렴(converge)합니다. 자세한 모델은 docs 참조.
```

```go
// Bad: reconnect를 백오프로 retry합니다
// Good: 재접속(reconnect)은 지수 백오프로 재시도합니다
```

## 6. AI투 뭉뚱그린 동사 지양

`Handle`, `Process`, `Manage`, `Perform`, `Execute` 대신 구체적 의도를 씁니다.

```go
// Bad: // Manage the connection.
// Good: // 끊기면 지수 백오프로 재연결합니다 (최대 30초)
```

## 7. TODO는 owner 또는 issue 포함

허용: `TODO(team-platform):`, `TODO(#123):`. 금지: bare `TODO:`, `FIXME:`.

```go
// Bad: // TODO: fix this later
// Good: // TODO(#412): watch 재수립 시 resourceVersion 손실 — informer 도입 후 제거
```

## 8. Advisory, minimal-diff 태도

주석 리뷰는 제안입니다. 저자 스타일을 존중하고 무단 전면 재작성을 하지 않습니다. 계약, 보안, 동시성 오류만 `must-fix`로 강하게 밀고, 나머지는 근거와 함께 제안합니다.
