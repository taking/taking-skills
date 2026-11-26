# go (Go 문화 규칙)

Effective Go, Go Code Review Comments, Go Doc Comments 관례. GoDoc은 **식별자 이름으로 시작하는 완전한 문장**입니다.

---

## 목차

- 1. GoDoc은 식별자 이름으로 시작합니다
- 2. getter에 Get 접두사를 붙이지 않습니다
- 3. 에러는 %w로 감싸고, sentinel, typed 에러를 문서화합니다
- 4. 동시성 소유권을 문서화합니다
- 5. 공개는 문서화, 내부는 최소화
- 6. 패키지 doc은 doc.go에
- 7. //nolint에는 근거를 붙입니다

## 1. GoDoc은 식별자 이름으로 시작합니다

`godoc`이 이름과 함께 렌더링하므로 이름으로 시작해야 문장이 완성됩니다. 완전한 문장(마침표 포함)으로 씁니다.

```go
// Bad: 이름 없이 시작 — godoc에서 문장이 깨집니다
// Returns a tunnel bound to the given cluster.
func NewTunnel(id ClusterID) *Tunnel

// Good: 식별자 이름으로 시작하는 완전한 문장
// NewTunnel returns a reverse tunnel bound to clusterID.
// The caller owns the returned *Tunnel and must call Close.
func NewTunnel(id ClusterID) *Tunnel
```

## 2. getter에 Get 접두사를 붙이지 않습니다

Go 관례상 필드 접근자는 `Get`을 뺍니다. 주석으로 "gets the..."라고 쓰지도 않습니다.

```go
// Bad
// GetOwner returns the owner. 
func (t *Tunnel) GetOwner() string

// Good
// Owner reports the tenant that opened the tunnel.
func (t *Tunnel) Owner() string
```

## 3. 에러는 %w로 감싸고, sentinel, typed 에러를 문서화합니다

`errors.Is`/`errors.As` 계약을 문서에 명시합니다. 감싸는 이유가 문맥 추가면 그대로 두고, 아니면 명시적 에러를 노출합니다.

```go
// Bad: 계약이 숨겨짐 — 호출자가 무엇으로 분기할지 모릅니다
func Send(ev Event) error

// Good: 반환 가능한 sentinel을 문서화
// Send publishes ev to Kafka. It returns ErrTunnelClosed if the tunnel was
// closed concurrently; callers should treat that as retryable via a new tunnel.
var ErrTunnelClosed = errors.New("tunnel: closed")

func Send(ev Event) error {
    if t.closed.Load() {
        // %w로 감싸 errors.Is(err, ErrTunnelClosed)가 동작하게 합니다
        return fmt.Errorf("send %s: %w", ev.ID, ErrTunnelClosed)
    }
    ...
}
```

## 4. 동시성 소유권을 문서화합니다

goroutine 수명 소유자, mutex가 **무엇을** 보호하는지, context 취소 전파를 적습니다.

```go
// Bad: 락이 뭘 지키는지 불명
var mu sync.Mutex

// Good: 보호 대상과 소유권 명시
// mu guards conns and closed. Never hold mu across a network call —
// Send blocks on the wire and would serialize all tunnels.
var mu sync.Mutex

// run owns the read loop goroutine. It exits when ctx is cancelled OR the
// stream returns io.EOF; the caller must not read t.conn after run returns.
func (t *Tunnel) run(ctx context.Context) { ... }
```

## 5. 공개는 문서화, 내부는 최소화

exported 심볼은 GoDoc 필수(목적, 계약, 에러, 동시성). unexported, 자명한 헬퍼는 Why, 제약만, 없으면 달지 않습니다.

```go
// Good: unexported지만 비자명한 제약이 있어 남깁니다
// backoff caps at 30s: apiserver rejects reconnects faster than that under load.
func backoff(attempt int) time.Duration
```

## 6. 패키지 doc은 doc.go에

패키지 목적, 경계는 `doc.go`의 package 주석에 둡니다. 여러 파일에 흩지 않습니다.

```go
// Good: doc.go
// Package tunnel implements the reverse gRPC tunnel from agent to control plane.
// It intentionally does not import client-go: the tunnel moves opaque bytes and
// must not parse apiserver responses.
package tunnel
```

## 7. //nolint에는 근거를 붙입니다

린터를 끌 때는 왜 안전한지 한 줄로 남깁니다.

```go
// Bad
//nolint:errcheck
conn.Close()

// Good
//nolint:errcheck // best-effort close on shutdown path; error is already logged upstream
conn.Close()
```
