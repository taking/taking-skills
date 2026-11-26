# <컴포넌트> Troubleshooting

<!-- 채우기: H1은 대상 컴포넌트. "<컴포넌트> Troubleshooting". -->

## Overview

<!-- 채우기: 무슨 문제 영역인가. 3~6줄. -->
`<컴포넌트>`에서 자주 나오는 증상과 해결을 정리합니다.

## Symptom → Cause → Fix

<!-- 채우기: 핵심 표. 증상-원인-해결. 완결 문장 X. -->
| 증상 | 원인 | 해결 |
| --- | --- | --- |
| `<Pod CrashLoopBackOff>` | `<원인>` | `<해결>` |
| `<gRPC UNAVAILABLE>` | `<원인>` | `<해결>` |
| `<이벤트 미수신>` | `<원인>` | `<해결>` |

## Diagnostics

<!-- 채우기: 진단 명령. 각 명령에 목적. -->
```bash
# <목적: Pod 상태 확인>
kubectl get pods -n <namespace> -o wide

# <목적: 로그 확인>
kubectl logs <pod> -n <namespace> --tail=100

# <목적: 이벤트 확인>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

| 신호 | 확인 명령 | 정상 값 |
| --- | --- | --- |
| `<신호>` | `<command>` | `<정상 값>` |

## Escalation

<!-- 채우기: 해결 안 될 때. 표. -->
| 조건 | 대상 | 채널 |
| --- | --- | --- |
| `<조건>` | `<팀 / 담당>` | `<채널>` |

## References

- [<Runbook / Architecture>](<경로>)
