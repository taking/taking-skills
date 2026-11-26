# security 템플릿

보안 가정을 명시합니다: **trust boundary**(어디서부터 신뢰 안 하는가), authn/authz, 입력 검증, sanitization, 민감 데이터 취급. 코드는 "무엇을 검사하는가"만 보이고 "무엇을 신뢰하는가"는 안 보입니다.

## 왜/언제

- **언제**: 신뢰 경계를 넘는 지점(외부 입력 수신, 권한 검사, 토큰, 비밀 취급, 역직렬화, 명령/쿼리 조립).
- **왜**: 다음 사람이 "이 값은 이미 검증됐다"를 모르면 중복 검증하거나(안전), 검증을 건너뜁니다(취약). 신뢰 경계를 적으면 각 계층의 책임이 분명해집니다.
- **적을 것**: 무엇을 신뢰하고 무엇을 신뢰하지 않는가, 누가 authn/authz했는가, 검증, sanitize한 것과 남은 책임, 민감 데이터를 로그, 에러에 노출하지 않는 근거.

## 스켈레톤

```go
// <Func> <목적>.
//
// Trust boundary: <입력의 출처. 신뢰하는가? 어디서 검증됐는가?>.
// AuthZ: <이 함수가 권한을 검사하는가, 아니면 호출자가 이미 했다고 가정하는가>.
// Validation: <여기서 검증, sanitize하는 것. 호출자에게 남기는 책임>.
// Sensitive data: <비밀, PII를 어떻게 다루는가. 로그, 에러 노출 금지 근거>.
func <Func>(<params>) (<results>) {
```

## Good example

```go
// RenderQuery builds the SQL for a tenant-scoped search.
//
// Trust boundary: filter comes straight from the HTTP request body and is
// UNTRUSTED. tenantID is trusted: the auth middleware set it from the verified
// JWT, not from any client-supplied field.
// AuthZ: this function does NOT check authorization; the caller must have
// resolved tenantID from an authenticated principal. Passing a client-supplied
// tenantID here is a privilege-escalation bug.
// Validation: filter.Field is checked against an allowlist of column names
// (defense against SQL injection via identifiers, which cannot be
// parameterized); filter.Value is always bound as a query parameter, never
// concatenated.
// Sensitive data: the assembled query is not logged at info level. It can
// embed tenant identifiers; only the parameterized template is logged.
func RenderQuery(tenantID string, filter SearchFilter) (string, []any, error) {
	col, ok := allowedColumns[filter.Field]
	if !ok {
		return "", nil, ErrInvalidField // reject unknown identifiers early.
	}
	return "SELECT id FROM docs WHERE tenant_id = $1 AND " + col + " = $2",
		[]any{tenantID, filter.Value}, nil
}
```
