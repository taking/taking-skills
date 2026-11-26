# godoc 템플릿

공개(exported) 함수, 타입의 GoDoc. 목적, 계약, 에러, 부작용, 동시성, 호환성만 적습니다. WHAT(구현 재진술)은 코드가 말하므로 쓰지 않습니다.

## 왜/언제

- **언제**: exported 함수, 타입, 메서드에 항상. 내부 헬퍼는 Why/제약만 필요할 때.
- **왜**: 호출자는 시그니처만 보고 계약을 판단합니다. 문서가 없으면 구현을 읽게 되고, 구현이 바뀌면 가정이 깨집니다.
- **관례**: 문장은 **식별자 이름**으로 시작합니다(`Fetch returns...`). 완전한 문장. 파라미터, 반환은 산문으로 엮되, 에러, 부작용, 동시성은 별도 문단.

## 스켈레톤 (func)

```go
// <FuncName> <목적: 무엇을 보장하는가, 3인칭 현재형>.
//
// <파라미터를 산문으로: 어떤 값이 유효한가, 경계, 전제조건>.
// <반환값의 의미: 성공 시 무엇을 보장하는가>.
//
// <에러 조건: 어떤 상황에서 어떤 에러를 반환하는가. sentinel이면 errors.Is 로 검사 가능함을 명시>.
// <부작용: 외부 상태 변경, I/O, 로깅 등 시그니처에 안 보이는 것. 없으면 이 줄 생략>.
// <동시성: 동시 호출 안전한가. context 취소를 어떻게 다루는가. 해당 없으면 생략>.
// <호환성: 안정성 보장, deprecated 여부, since 버전 등. 해당 없으면 생략>.
func <FuncName>(<params>) (<results>) {
```

## 스켈레톤 (type)

```go
// <TypeName> <이 타입이 표현하는 개념, 불변식>.
//
// <제로값이 유효한가. 생성자를 반드시 써야 하는가>.
// <동시성: 여러 goroutine에서 공유해도 되는가. 안 되면 그 이유>.
type <TypeName> struct {
```

## Good example

```go
// FetchManifest returns the rendered manifest for clusterID at the given
// revision. revision must be a positive generation observed via ListRevisions;
// revision 0 selects the latest committed revision.
//
// It returns ErrRevisionPruned when the revision existed but has been
// garbage-collected, so callers can distinguish it from ErrNotFound
// (checkable with errors.Is). The returned bytes are a fresh copy and safe
// to mutate.
//
// FetchManifest is safe for concurrent use. It honors ctx cancellation: a
// cancelled ctx aborts the backing store read and returns ctx.Err().
func FetchManifest(ctx context.Context, clusterID string, revision int64) ([]byte, error) {
```
