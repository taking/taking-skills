# checklist (리뷰 체크리스트)

## 리뷰 순서
1. **Improve Code** : 불명확한 구조를 먼저 고칩니다.
2. **Improve Naming** : 이름으로 해결되는지 봅니다.
3. **Remove** : 코드 재진술 주석을 지웁니다.
4. **Rewrite** : WHAT 주석을 WHY로 다시 씁니다.
5. **Add** : 가치 있는 주석만 더합니다.

## 심각도
- **must-fix** : 정확성, 계약, 보안, 동시성의 오류 또는 누락.
- **should** : 가독성, 유지보수성 저하.
- **nice** : 취향, 미세 개선.

## 주석마다 (유지/추가 판단)
- [ ] Delete-first : 지우면 **다음 사람이 코드를 잘못 고치나**? 아니오 → 삭제.
- [ ] 설계 서사가 아닌가(대안 비교, 채택 근거, 걷어낸 구현 회고, UX 근거, 저자 회고)?
- [ ] 사실 뒤에 습관적 정당화(`~므로 ~한다`)가 붙지 않았나?
- [ ] 아래 중 하나 이상을 설명하는가?
  - [ ] WHY / 의도
  - [ ] 제약(constraint)
  - [ ] 트레이드오프
  - [ ] 불변식(invariant)
  - [ ] 계약(contract)
  - [ ] 보안 가정
  - [ ] 동시성 의도
  - [ ] 성능 근거
- [ ] 리팩터링을 견디는가(구현 세부가 아니라 의미, 계약인가)?
- [ ] WHAT(코드 재진술)이 아닌가?

## 계약, 고위험 (있으면 문서화됐는가)
- [ ] wire protocol, header, label, annotation, eventType, Kafka topic, CRD field, feature flag, env var, serialization format, API 호환성
- [ ] 계약, 불변식, 보장 서술에 요구 수준(MUST/SHOULD/MAY) 영어 키워드를 명시했는가 (reference/requirement-levels.md)
- [ ] authn/authz, trust boundary, 입력 검증, 민감 데이터
- [ ] 동시성 프리미티브(goroutine/channel/mutex/atomic/context, synchronized/volatile/Lock/Atomic*/Executor)
- [ ] 성능 최적화(pooling/zero-copy/batching/caching/lazy)의 Why
- [ ] workaround의 이유, 제거 조건, 이슈 ID
- [ ] 고위험(unsafe/reflect/panic, recover, Reflection/Unsafe)의 안전 근거
- [ ] 공개 API의 GoDoc/JavaDoc 완비(목적, 파라미터, 반환, 에러, 부작용, 동시성, 호환성)
- [ ] 패키지/모듈 목적, 경계 주석

## 문체
- [ ] 산문은 한국어, 정착 용어는 영어(Cluster, Pod, CRD, Context 등). 억지 번역, 이중표기 남발 없음
- [ ] 의미를 가리는 개념(멱등, 수렴, 순단)은 첫 등장에 짧은 포인터만, 개념 설명은 문서로. 흔한 용어는 설명 안 함
- [ ] 다음 개발자(분산/K8s 비전문가) 기준으로 읽히는가
- [ ] 주석이 1–3줄인가(예외: architecture, security, protocol, concurrency). 5줄↑이면 문서로 옮기고 요약+참조만
- [ ] 한 줄이 80자 이내인가(줄바꿈 불가한 kubebuilder 마커, //nolint, struct tag, Javadoc 태그 행은 예외)
- [ ] 종결 톤이 존댓말 기본(또는 저장소 관례)을 따르는가
- [ ] 짧은 사실을 명사형으로 끊었는가(억지로 `~합니다`를 붙여 정당화가 늘지 않았나)
- [ ] 한 블록에서 같은 종결어미가 3줄 연속되지 않는가
- [ ] 문법 해설(`x += 1 // x를 1 늘린다`)이 없는가
- [ ] 소스는 이 코드를 설명하는가(기술 자체를 소스에서 가르치지 않음)
- [ ] AI투 뭉뚱그린 동사(Handle/Process/Manage…) 대신 구체적 의도
- [ ] TODO에 owner 또는 issue 포함, bare TODO/FIXME 없음
- [ ] 같은 사실을 여러 주석에 반복하지 않음(DRY)

## 태도
- [ ] Advisory : 리포트로 제안, 반영은 승인 후.
- [ ] Minimal-diff : 무단 전면 재작성 없이 저자 스타일 존중.
