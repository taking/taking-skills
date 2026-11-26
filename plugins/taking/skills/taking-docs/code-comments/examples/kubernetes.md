# kubernetes : CRD 타입, reconcile 계약 문서화

Kubernetes에서 문서화할 계약: **필드 의미, 불변성(immutable), reconcile 멱등성, RBAC 의도.** 이것들은 코드로 강제되지 않는 규약이라 반드시 적습니다.

---

## 목차

- 1. CRD 타입 : 필드 계약과 불변성
  - Before
  - Review
  - After
- 2. Reconcile 루프 : 멱등성, RBAC 의도
  - Before
  - Review
  - After

## 1. CRD 타입 : 필드 계약과 불변성

### Before

```go
// Workload is a workload
type Workload struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              WorkloadSpec   `json:"spec,omitempty"`
	Status            WorkloadStatus `json:"status,omitempty"`
}

// WorkloadSpec is the spec
type WorkloadSpec struct {
	// the tenant
	Tenant string `json:"tenant"`
	// number of replicas
	Replicas int32 `json:"replicas"`
	// the gpu class
	GPUClass string `json:"gpuClass"`
}
```

### Review
**Remove [should]** : `// Workload is a workload`, `// WorkloadSpec is the spec`, `// the tenant`, `// number of replicas`는 전부 식별자 재진술이라 삭제. **Add [must-fix]** : `Tenant`와 `GPUClass`는 사실상 **immutable 필드**일 가능성이 높습니다(테넌트/GPU 클래스가 바뀌면 재스케줄 불가). 불변 계약은 코드가 아니라 규약이므로 명시하고, webhook이 강제한다는 점을 남깁니다. **Add [must-fix]** : `Replicas`의 허용 범위, 기본값이 없습니다. CRD 필드는 API 계약이므로 kubebuilder 마커로 검증을 코드화하고, 왜 그 상한인지만 주석으로 남깁니다. **Add [should]** : `Status`는 컨트롤러만 쓰고 사용자는 못 쓴다는 소유권(subresource)을 재확인.

### After

```go
// Workload is the tenant-facing API object for a GPU workload. Users edit
// Spec; only the controller writes Status (status subresource).
type Workload struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`
	Spec              WorkloadSpec   `json:"spec,omitempty"`
	Status            WorkloadStatus `json:"status,omitempty"`
}

type WorkloadSpec struct {
	// Tenant is immutable after creation: it pins topic/ACL scoping, so a
	// change would orphan events. The validating webhook rejects updates.
	// +kubebuilder:validation:Required
	Tenant string `json:"tenant"`

	// +kubebuilder:validation:Minimum=0
	// +kubebuilder:validation:Maximum=64
	// 상한 64: 단일 tenant가 스케줄러 큐를 독점하지 못하게 하는 정책값
	Replicas int32 `json:"replicas"`

	// GPUClass is immutable: rescheduling to a different class requires a new
	// Workload, not an in-place edit. Enforced by the webhook.
	GPUClass string `json:"gpuClass"`
}
```

---

## 2. Reconcile 루프 : 멱등성, RBAC 의도

### Before

```go
// Reconcile reconciles the workload
func (r *WorkloadReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	var w Workload
	if err := r.Get(ctx, req.NamespacedName, &w); err != nil {
		return ctrl.Result{}, err
	}
	dep := buildDeployment(&w)
	if err := r.Create(ctx, dep); err != nil {
		return ctrl.Result{}, err
	}
	return ctrl.Result{}, nil
}
```

### Review
**Remove [should]** : `// Reconcile reconciles the workload`는 재진술. 삭제. **Improve Code [must-fix]** : `Create`만 호출해 멱등성이 깨집니다: 두 번째 reconcile에서 `AlreadyExists`로 실패합니다. reconcile은 여러 번 호출되므로 create-or-update여야 합니다. 이건 코드 결함. **Improve Code [must-fix]** : 삭제된 객체(`NotFound`)를 에러로 반환해 무한 재큐됩니다. `IgnoreNotFound` 처리 필요. **Add [must-fix]** : reconcile **멱등성 계약**을 명시(설계 불변식이며 리네이밍으로 안 드러남). **Add [should]** : 이 컨트롤러가 필요로 하는 RBAC 의도를 kubebuilder 마커로 코드화하고, 왜 그 권한까지만 필요한지(최소 권한) 남깁니다.

### After

```go
// Reconcile is idempotent: the apiserver may call it many times for the same
// Workload, so every step is create-or-update and a missing object is a
// no-op (the owned Deployment is garbage-collected by owner reference).
//
// RBAC: needs deployments write to materialize the workload, and workloads
// status write to report phase — nothing broader, to keep least privilege.
// +kubebuilder:rbac:groups=xpu.io,resources=workloads,verbs=get;list;watch
// +kubebuilder:rbac:groups=xpu.io,resources=workloads/status,verbs=update
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;create;update
func (r *WorkloadReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	var w Workload
	if err := r.Get(ctx, req.NamespacedName, &w); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
	if err := r.apply(ctx, buildDeployment(&w)); err != nil { // create-or-update
		return ctrl.Result{}, err
	}
	return ctrl.Result{}, nil
}
```
