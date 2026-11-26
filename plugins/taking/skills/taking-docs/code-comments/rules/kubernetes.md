# kubernetes (CRD, 컨트롤러 계약 문서화)

CRD 필드 주석은 `kubectl explain`으로 사용자에게 노출됩니다. 라벨, 어노테이션 계약, reconcile 가정, 멱등성, RBAC 의도, feature flag, env var 계약을 문서화합니다.

---

## 1. CRD 필드 주석은 사용자 문서입니다

`+kubebuilder` 마커 위 주석이 그대로 `kubectl explain`에 뜹니다. 의미, 단위, 기본값, 제약을 적습니다.

```go
// Bad: 타입만 있고 계약 없음 — explain이 비어 보입니다
type ClusterAgentSpec struct {
    ReconcileInterval int `json:"reconcileInterval"`
}

// Good: 단위, 범위, 기본값이 explain에 노출됩니다
type ClusterAgentSpec struct {
    // ReconcileInterval is the seconds between tunnel health probes.
    // Must be >= 5; lower values overload the control-plane apiserver.
    // Defaults to 30 when omitted.
    // +kubebuilder:validation:Minimum=5
    // +kubebuilder:default=30
    ReconcileInterval int `json:"reconcileInterval,omitempty"`
}
```

## 2. 라벨, 어노테이션은 계약으로 문서화합니다

키, 값 형식, 소비자를 상수 옆에 남깁니다. 오타, 리네임이 조용한 셀렉터 실패를 낳습니다.

```go
// Bad
const clusterLabel = "xpu.io/cluster-id"

// Good
// LabelClusterID pins a resource to its origin cluster. The tunnel controller
// selects on this label; changing the key silently breaks tunnel routing for
// existing objects. Value is the ClusterID, RFC 1123 label (<= 63 chars).
const LabelClusterID = "xpu.io/cluster-id"
```

## 3. reconcile 가정, 멱등성을 밝힙니다

Reconcile은 언제든 재호출됩니다. 재진입 안전성, 부분 실패 처리를 문서화합니다.

```go
// Good
// Reconcile is idempotent and edge-trigger agnostic: it derives desired state
// solely from the observed CR + apiserver, never from event deltas. A requeue
// after partial apply is safe — CreateOrUpdate is used for every child object.
func (r *AgentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error)
```

## 4. RBAC 마커의 의도를 적습니다

권한을 왜 넓혔는지 남깁니다. 최소 권한 원칙 위반은 감사 대상입니다.

```go
// Bad
// +kubebuilder:rbac:groups="",resources=secrets,verbs=get;list;watch

// Good: 왜 secret 접근이 필요한지 — 감사 시 근거가 됩니다
// Needs secrets to read the per-cluster mTLS keypair used to dial the tunnel.
// Scope stays namespace-local via the Role (not ClusterRole) binding.
// +kubebuilder:rbac:groups="",resources=secrets,verbs=get;list;watch
```

## 5. feature flag, env var를 계약으로 문서화합니다

플래그 기본값, 제거 조건, 읽는 시점(부팅 시 1회 vs 매번)을 남깁니다.

```go
// Good
// ENABLE_KAFKA_FALLBACK routes events through Kafka when the tunnel is down.
// Read once at startup; changing it requires a pod restart. Default false.
// Remove once the tunnel SLO holds for 2 releases (TODO(#508)).
const envEnableKafkaFallback = "ENABLE_KAFKA_FALLBACK"
```
