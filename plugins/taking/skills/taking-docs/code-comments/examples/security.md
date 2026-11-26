# security : 신뢰 경계, 인증, 입력 검증 문서화

보안 가정은 코드에 안 보입니다: **어디가 신뢰 경계인지, 무엇이 검증됐다고 가정하는지, 왜 이 권한으로 충분한지**. 등장 시 문서화 필수.

---

## 목차

- 1. 신뢰 경계 : 터널로 들어온 프레임
  - Before
  - Review
  - After
- 2. 인증, 인가 : 토큰 검증 가정
  - Before
  - Review
  - After
- 3. 입력 검증 : 로그로 새는 민감 데이터
  - Before
  - Review
  - After

## 1. 신뢰 경계 : 터널로 들어온 프레임

### Before

```go
func (s *Server) onTunnelFrame(f Frame) error {
	req, err := decodeRequest(f.Payload)
	if err != nil {
		return err
	}
	return s.apiserver.Do(req)
}
```

### Review
**Add [must-fix]** : 이 함수는 신뢰 경계입니다: `f.Payload`는 클러스터 안 agent가 보낸, **신뢰할 수 없는** 바이트입니다. 그런데 검증 없이 apiserver로 그대로 넘깁니다. "여기서부터 신뢰 불가"라는 경계와, 검증 책임이 어디 있는지가 문서화돼야 합니다. **Improve Code [must-fix]** : 경계 검증(테넌트 범위, 허용 verb)이 아예 없다면 이건 주석이 아니라 코드 결함입니다. 최소한 요청의 tenant가 이 터널 세션의 tenant와 일치하는지 확인해야 합니다. **Improve Naming [should]** : `onTunnelFrame`은 AI투 이벤트 핸들러명입니다. `forwardTenantScopedRequest`처럼 무엇을 보장하는지 드러내는 이름이 낫습니다.

### After

```go
// forwardTenantScopedRequest is the trust boundary for the reverse tunnel:
// f.Payload is attacker-controlled data from an in-cluster agent and must not
// be trusted. We reject any request whose tenant does not match the tenant
// bound to this session at dial time, so a compromised agent cannot act
// across tenants.
func (s *Server) forwardTenantScopedRequest(sess *Session, f Frame) error {
	req, err := decodeRequest(f.Payload)
	if err != nil {
		return fmt.Errorf("decode tunnel frame: %w", err)
	}
	if req.Tenant != sess.Tenant {
		return ErrTenantMismatch
	}
	return s.apiserver.Do(req)
}
```

---

## 2. 인증, 인가 : 토큰 검증 가정

### Before

```java
public Response handle(HttpRequest req) {
    String token = req.header("Authorization");
    Claims claims = jwt.parse(token);      // trusts signature
    return router.route(req, claims.tenant());
}
```

### Review
**Add [must-fix]** : `jwt.parse`가 서명, 만료, audience를 실제로 검증하는지가 이 코드의 보안 전체를 좌우합니다. "parse가 검증까지 한다"는 가정이 문서화돼야 하고, 안 한다면 코드 결함입니다. **Add [must-fix]** : 인가(authz)가 없습니다: `claims.tenant()`가 요청 경로의 tenant와 일치하는지 확인하지 않으면, 유효한 토큰 하나로 남의 tenant에 접근합니다(IDOR). authz 지점과 가정을 명시합니다. **Improve Naming [should]** : `handle`은 뭉뚱그린 동사입니다. 이름에 authz 책임을 드러냅니다.

### After

```java
/**
 * Entry point after TLS termination; treats the request as untrusted until
 * the token is validated.
 *
 * <p>Security contract: {@code jwt.parse} verifies signature, expiry, and
 * audience and throws on any failure — callers rely on that, so it must never
 * be relaxed to a decode-only path. Authorization is enforced here by
 * requiring the token's tenant to match the routed tenant; a valid token for
 * tenant A cannot reach tenant B.
 */
public Response authenticateAndRoute(HttpRequest req) {
    String token = req.header("Authorization");
    Claims claims = jwt.parse(token);
    String routedTenant = req.pathParam("tenant");
    if (!claims.tenant().equals(routedTenant)) {
        throw new ForbiddenException("token tenant does not match route");
    }
    return router.route(req, claims.tenant());
}
```

---

## 3. 입력 검증 : 로그로 새는 민감 데이터

### Before

```go
func login(u, p string) error {
	log.Printf("login attempt: user=%s pass=%s", u, p)
	return auth.Verify(u, p)
}
```

### Review
**Improve Code [must-fix]** : 비밀번호를 평문 로그로 남깁니다. 이건 심각한 데이터 노출이며, 주석이 아니라 즉시 제거 대상입니다. **Add [should]** : 왜 사용자 식별자만 남기고 자격 증명은 절대 로그에 넣지 않는지, 그 정책을 한 줄로 남겨 재발을 막습니다.

### After

```go
func login(u, p string) error {
	// 민감 데이터 로깅 금지: 자격 증명(비밀번호, 토큰)은 로그, 에러 메시지에 넣지 않습니다
	log.Printf("login attempt: user=%s", u)
	return auth.Verify(u, p)
}
```
