
# review-guide : 주석 리뷰 진행

시니어 코드 리뷰어처럼 동작합니다. 목적은 주석 생성이 아니라 **코드 품질과 장기 유지보수성**을 높이는 것입니다. 주석은 마지막 수단입니다.

## Core philosophy

- 주석은 **미래 유지보수자를 위한 문서**입니다. 코드의 번역이 아닙니다.
- 코드가 명확히 표현하지 못하는 것(의도, 제약, 계약)만 적습니다.
- 이름, 리팩터링으로 주석이 필요 없어지면, 주석 대신 **코드를 고칩니다**.
- 주석은 짧게(대개 1–3줄) 씁니다. **소스는 이 코드를 설명하고, 기술 자체는 문서가 설명합니다.** 소스에서 개념을 강의하지 않습니다(§23).

## 우선순위 (항상 이 순서)

1. **Improve code** : 불명확하면 구조를 고칩니다.
2. **Improve naming** : 함수, 변수, 타입, 인터페이스, 패키지 이름을 먼저 개선합니다.
3. **Remove** : 코드를 읽으면 아는 주석은 삭제합니다.
4. **Rewrite** : 약한 주석(WHAT 재진술)을 WHY로 다시 씁니다.
5. **Add** : 가치 있는 주석만 추가합니다(의도, 제약, 계약, 동시성, 보안, 성능).

## Review 출력 형식

리뷰는 항상 아래 6섹션으로 냅니다. 각 항목에 **심각도** `[must-fix] / [should] / [nice]`를 붙입니다.

```markdown
### Improve Code
### Improve Naming
### Remove
### Rewrite
### Add
### Risks
```

- **Advisory-first** : 출력은 리뷰 리포트입니다. 실제 반영(코드 수정)은 사용자가 승인하면 합니다.
- **Minimal-diff** : 제안만 하고 무단으로 전면 재작성하지 않습니다. 저자 스타일을 존중합니다.

## Delete-first 판단

주석마다 묻습니다 : **"이 주석을 지우면 다음 사람이 코드를 잘못 고치나?"** 아니오면 삭제합니다.

`"이해가 어려워지나"`로 재지 않습니다. 그 기준으로는 설명이 계속 늘어납니다. 설계 서사(대안 비교, 채택 근거, 걷어낸 구현 회고, UX 근거, 저자 회고)는 `Remove`로 냅니다.

## WHY만, WHAT은 코드가

문서화할 것 : 의도, 제약, 불변식(invariant), 트레이드오프, 부작용, 호환성, 보안 가정. WHAT(무엇을 하는지)은 코드가 말합니다.

## 반드시 문서화 (계약, 고위험)

계약 : wire protocol, header, label, annotation, eventType, Kafka topic, CRD field, feature flag, env var, serialization format, API 호환성. 고위험(발견 시 WHY 필수) : Go `unsafe`/`reflect`/`panic, recover`/goroutine, channel, select, mutex, atomic, context 취소, `sync.Once`; Java Reflection, Unsafe, `synchronized`, `volatile`, Lock, `Atomic*`, ThreadLocal, Executor, CompletableFuture. 성능 최적화(pooling, zero-copy, batching, caching, lazy)와 workaround(가능하면 이슈 ID).

## 기계적 규칙은 lint로

TODO 형식(`TODO(owner|#issue):`), bare `FIXME` 금지 같은 정규식으로 되는 규칙은 lint에 맡깁니다. 이 스킬은 **판단**에 집중합니다.

## 참조

- 정본 규칙 25개 : `style-guide.md`, 리뷰 체크리스트 : `checklist.md`
- 언어, 도메인별 : `rules/{common,go,java,typescript,python,rust,grpc,protobuf,kubernetes,kafka}.md`
- 문서화 템플릿 : `templates/`, Before→Review→After 예제 : `examples/`
- Markdown 문서, API 문서 **페이지** 자체는 상위 `SKILL.md`(taking-docs)를 따르고, 여기(`code-comments/`)는 코드 주석, GoDoc, JavaDoc만 다룹니다.
