# kubernetes 템플릿

CRD 필드와 컨트롤러의 doc. 필드는 `kubectl explain`에 그대로 노출되므로 사용자 관점의 의미를 적습니다. 기본값, 불변성, reconcile 가정, RBAC 의도를 명시합니다.

## 왜/언제

- **언제**: CRD 타입 필드(kubebuilder 마커 포함), reconcile 루프, controller 진입점.
- **왜**: 필드 주석은 API 계약이자 사용자 문서입니다. 불변(immutable) 여부와 기본값이 없으면 사용자가 바꿀 수 없는 필드를 바꾸려다 실패합니다. reconcile 가정(무엇을 sole owner로 보는가)이 없으면 다른 컨트롤러와 충돌합니다.
- **적을 것**: 필드 의미(사용자 언어), default, 필수/선택, immutability, reconcile 전제(소유, idempotency), 필요한 RBAC와 그 이유.

## 스켈레톤 (Go types)

```go
// <Spec> <이 리소스가 선언하는 desired state>.
type <Spec> struct {
	// <Field> <사용자 관점 의미>.
	// <불변이면 명시: immutable, 변경하려면 리소스 재생성>.
	//
	// +kubebuilder:validation:Required   // 또는 +optional
	// +kubebuilder:default=<value>
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="<field> is immutable"
	<Field> <type> `json:"<field>"`
}

// +kubebuilder:rbac:groups=<group>,resources=<res>,verbs=<verbs>
// <RBAC 의도: 왜 이 verb가 필요한가>.
//
// Reconcile <무엇을 desired state로 수렴시키는가>.
// Assumes <전제: 이 컨트롤러가 <owned resource>의 유일한 소유자>.
// Idempotent: <같은 spec 재입력 시 no-op 보장>.
func (r *<Reconciler>) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
```

## Good example

```go
// ClusterAgentSpec is the desired state of a managed cluster agent.
type ClusterAgentSpec struct {
	// ClusterID is the control-plane identifier this agent binds to. It is
	// immutable: an agent cannot be re-pointed at another cluster because its
	// tunnel credentials are minted per cluster. Rebind by recreating the CR.
	//
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="clusterID is immutable"
	ClusterID string `json:"clusterID"`

	// Replicas is the desired number of agent pods. Defaults to 1; more than
	// one is only useful for active/standby, never active/active (the tunnel
	// admits a single writer per cluster).
	//
	// +optional
	// +kubebuilder:default=1
	// +kubebuilder:validation:Minimum=1
	Replicas int32 `json:"replicas,omitempty"`
}

// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch
// Needs write on Deployments because it owns the agent Deployment; watch keeps
// the status in sync when a node reschedules the pod.
//
// Reconcile converges the agent Deployment to match spec.Replicas and the
// pinned image. It assumes it is the sole owner of the Deployment named
// "<cr.Name>-agent" and will overwrite manual edits. Idempotent: re-running
// with an unchanged spec produces no API writes.
func (r *ClusterAgentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
```
