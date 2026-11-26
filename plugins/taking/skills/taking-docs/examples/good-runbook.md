# Control Plane CA 교체 Runbook

운영 작업 Runbook의 모범 예시입니다. 순서가 결과를 바꾸는 작업을 번호 목록으로 쓰는 방법(§4.3)을 보여 줍니다. 각 단계는 실행할 명령과 다음 단계로 넘어가기 전 확인 포인트를 함께 둡니다.

## Overview

Control Plane CA를 새 키 쌍으로 교체합니다. CA 만료가 가까워졌거나 CA 개인 키가 유출된 상황에서 실행합니다. CA는 Agent와 Control Plane 사이 mTLS 인증서를 서명하므로, 교체 중 신뢰 체계가 어긋나면 전체 tunnel이 끊깁니다.

| 항목 | 값 |
| --- | --- |
| 목적 | Control Plane CA 교체 (만료 임박 또는 키 유출 대응) |
| 대상 | Control Plane, 전체 Cluster Agent |
| 소요 시간 | 약 30분 (Agent 수에 비례) |
| 위험도 | High (순서 오류 시 전체 tunnel 끊김) |

## Prerequisites

- **CA 서명 권한:** 새 CA 키 쌍을 만들고 cert를 발급할 수 있는 PKI 접근 (`step-ca` admin)
- **kubeconfig:** Control Plane과 각 cluster의 `cluster-admin` RBAC
- **도구 버전:** `step` 0.25 이상, `kubectl` 1.28 이상
- **현재 상태:** 모든 Agent가 old CA로 Control Plane에 연결된 정상 상태. `kubectl get agents`로 전부 `Connected`인지 먼저 확인합니다.
- **백업:** 기존 CA 인증서와 trust store ConfigMap을 롤백용으로 보관

## Steps

순서가 결과를 바꿉니다. 2번(trust store에 새 CA 추가)을 3번(서버 cert 재발급)보다 먼저 하지 않으면, Agent가 새 cert를 신뢰하지 못해 tunnel이 전부 끊깁니다. 5번(old CA 제거)은 모든 Agent가 새 cert로 재연결된 뒤에만 실행합니다.

1. **새 CA 생성:** 새 CA 키 쌍과 인증서를 만듭니다. 기존 CA는 아직 그대로 둡니다.
   ```bash
   step certificate create "Control Plane CA v2" \
     ca-v2.crt ca-v2.key --profile root-ca --no-password --insecure
   ```
   - 확인: `step certificate inspect ca-v2.crt`로 `Not After`가 1년 뒤인지, `CA:TRUE`인지 확인합니다.
2. **trust store에 새 CA 추가:** 모든 Agent의 trust store에 new CA를 더합니다. 이 시점에는 old CA와 new CA를 둘 다 신뢰합니다.
   ```bash
   kubectl create configmap tunnel-ca-bundle \
     --from-file=ca.crt=<(cat ca-v1.crt ca-v2.crt) \
     -n agent-system --dry-run=client -o yaml | kubectl apply -f -
   ```
   - 확인: Agent가 번들을 다시 읽을 때까지 기다린 뒤, 한 Agent에서 `kubectl exec`로 trust store에 두 CA가 모두 있는지 확인합니다. 둘 다 신뢰하기 전에 3번으로 넘어가지 않습니다.
3. **Control Plane 서버 cert 재발급:** 서버 cert를 new CA로 재발급하고 Control Plane을 롤링 재시작합니다.
   ```bash
   step certificate sign cp.csr ca-v2.crt ca-v2.key > cp-v2.crt
   kubectl rollout restart deploy/control-plane -n cp-system
   ```
   - 확인: `kubectl rollout status`로 재시작이 끝나면, Agent 로그에 핸드셰이크 오류가 없고 `kubectl get agents`가 여전히 전부 `Connected`인지 확인합니다.
4. **Agent client cert 재발급:** 각 Agent의 client cert를 new CA로 재발급합니다. Agent는 새 cert로 재연결합니다.
   ```bash
   step certificate sign agent.csr ca-v2.crt ca-v2.key > agent-v2.crt
   kubectl rollout restart daemonset/agent -n agent-system
   ```
   - 확인: 모든 Agent가 new cert로 재연결될 때까지 `kubectl get agents -w`로 지켜봅니다. 하나라도 `Disconnected`로 남으면 5번으로 넘어가지 않습니다.
5. **old CA 제거:** trust store에서 old CA를 빼고 new CA만 남깁니다. 이 단계 뒤에는 old CA로 서명된 cert를 더 받지 않습니다.
   ```bash
   kubectl create configmap tunnel-ca-bundle \
     --from-file=ca.crt=ca-v2.crt \
     -n agent-system --dry-run=client -o yaml | kubectl apply -f -
   ```
   - 확인: Agent가 번들을 다시 읽은 뒤에도 전부 `Connected`인지 확인합니다.

## Verification

교체가 끝나면 tunnel 왕복과 cert 체인을 함께 확인합니다.

```bash
kubectl get agents -o wide
kubectl --context=<cluster> get ns   # tunnel 경유 요청
```

| 확인 항목 | 기대 결과 |
| --- | --- |
| Agent 연결 상태 | 전체 `Connected` |
| tunnel 경유 kubectl | 정상 응답 |
| 서버 cert 발급자 | `Control Plane CA v2` |
| Control Plane 로그 | 핸드셰이크 오류 없음 |

## Rollback

5번(old CA 제거) 이전이면 old CA가 trust store에 남아 있으므로, cert만 되돌리면 복구됩니다.

1. **서버 cert 복구:** 서버 cert를 old CA 서명본으로 되돌리고 Control Plane을 롤링 재시작합니다.
   ```bash
   kubectl rollout undo deploy/control-plane -n cp-system
   ```
   - 확인: 재시작 후 Agent 핸드셰이크가 복구되는지 로그로 확인합니다.
2. **Agent cert 복구:** Agent cert를 old CA 서명본으로 되돌립니다.
   ```bash
   kubectl rollout undo daemonset/agent -n agent-system
   ```
   - 확인: `kubectl get agents`가 전부 `Connected`로 돌아오는지 확인합니다.
3. **새 CA 정리:** 교체를 포기하는 경우, trust store에서 new CA를 빼고 old CA만 남깁니다.
   ```bash
   kubectl create configmap tunnel-ca-bundle \
     --from-file=ca.crt=ca-v1.crt \
     -n agent-system --dry-run=client -o yaml | kubectl apply -f -
   ```
   - 확인: 번들 재적용 후에도 전체 Agent가 `Connected`인지 확인합니다.

## References

- [RFC 5280: Internet X.509 PKI Certificate](https://www.rfc-editor.org/rfc/rfc5280)
- [step-ca: Certificate Authority](https://smallstep.com/docs/step-ca/)
- [Kubernetes: Rotate CA Certificates](https://kubernetes.io/docs/tasks/tls/manual-rotation-of-ca-certificates/)
