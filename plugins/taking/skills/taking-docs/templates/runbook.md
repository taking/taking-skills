# <작업> Runbook

<!-- 채우기: H1은 운영 작업. "<작업> Runbook" (예: Agent 배포, 롤백). -->

## Overview

<!-- 채우기: 무슨 작업인가. 언제 실행하나. 3~6줄 또는 표. -->
| 항목 | 값 |
| --- | --- |
| 목적 | `<작업 목적>` |
| 대상 | `<Cluster / namespace>` |
| 소요 시간 | `<예상 시간>` |
| 위험도 | `<Low / Med / High>` |

## Prerequisites

<!-- 채우기: 사전 조건 bullet. -->
- `<접근 권한 (kubeconfig, RBAC)>`
- `<도구 버전 (helm, kubectl)>`
- `<선행 상태>`

## Steps

<!-- 채우기: 순서가 의미 있으므로 번호 목록. 각 단계에 명령. -->
1. `<단계 1>`
   ```bash
   kubectl <command>
   ```
2. `<단계 2>`
   ```bash
   helm <command>
   ```
3. `<단계 3>`

## Verification

<!-- 채우기: 성공 확인 방법. 명령 + 기대 출력. -->
```bash
kubectl get pods -n <namespace>
```
기대: `<모든 Pod Running>`

| 확인 항목 | 기대 결과 |
| --- | --- |
| `<Pod 상태>` | `Running` |
| `<이벤트 발행>` | `<확인>` |

## Rollback

<!-- 채우기: 실패 시 되돌리기. 번호 목록. -->
1. `<롤백 단계 1>`
   ```bash
   helm rollback <release> <revision>
   ```
2. `<롤백 검증>`

## Escalation

<!-- 채우기: 안 되면 누구에게. 표. -->
| 조건 | 대상 | 채널 |
| --- | --- | --- |
| `<조건>` | `<팀 / 담당>` | `<채널>` |
