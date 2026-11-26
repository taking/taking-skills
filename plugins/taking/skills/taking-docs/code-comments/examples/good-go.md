# good-go : 이미 모범적인 Go 파일

목표 상태를 보여줍니다. Before가 이미 좋습니다 → Review는 대부분 "변경 없음" + 사소한 nit 두 개 → After는 미세 개선만. 전면 재작성하지 않습니다(minimal-diff).

포인트: GoDoc 식별자-우선 문장, 패키지 doc, `%w` 에러 래핑, WHY 주석만.

---

## 목차

- Before
- Review
  - Improve Code
  - Improve Naming
  - Remove
  - Rewrite
  - Add
  - Risks
- After

## Before

```go
// Package tunnel implements the reverse gRPC tunnel from an in-cluster agent
// to the control plane. It moves opaque bytes and deliberately does not depend
// on client-go: parsing apiserver responses is the caller's job, not the
// tunnel's.
package tunnel

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// ErrClosed is returned by Send after the session has been closed. Callers
// should treat it as terminal and re-dial rather than retrying on the same
// session.
var ErrClosed = errors.New("tunnel: session closed")

// Session is a single multiplexed connection to the control plane. A Session
// is safe for concurrent use by multiple goroutines.
type Session struct {
	stream grpcStream
	// deadline bounds a single Send; it is not the session lifetime.
	deadline time.Duration
}

// Send forwards one frame to the control plane and blocks until the frame is
// acknowledged or ctx is done. It returns ErrClosed if the session was closed
// concurrently, or a wrapped context error on deadline. Send is a no-op for a
// zero-length payload.
func (s *Session) Send(ctx context.Context, payload []byte) error {
	if len(payload) == 0 {
		return nil
	}
	ctx, cancel := context.WithTimeout(ctx, s.deadline)
	defer cancel()

	if err := s.stream.SendMsg(ctx, payload); err != nil {
		return fmt.Errorf("tunnel: send frame: %w", err)
	}
	return nil
}
```

## Review

전반적으로 목표 상태에 가깝습니다. 패키지 doc이 목적과 **경계**(client-go 비의존)를 명시했고, 공개 API에 목적, 에러 조건, 동시성 안전성이 문서화됐으며, 에러는 `%w`로 래핑됩니다. 대부분 변경 없음.

### Improve Code
- 변경 없음.

### Improve Naming
- 변경 없음. `Session`, `Send`, `ErrClosed` 모두 관례에 맞습니다.

### Remove
- `// deadline bounds a single Send; it is not the session lifetime.` : 삭제 후보로 검토했으나 유지. 필드명만으로는 "세션 수명"과 혼동할 여지가 있어 지우면 정보가 줍니다(delete-first 통과). [nice]

### Rewrite
- `Send`의 `// Send is a no-op for a zero-length payload.` 는 WHAT에 가깝습니다. 다만 공개 계약(빈 payload 허용)이라 유지 정당. 문장을 계약 톤으로만 다듬습니다: 빈 payload를 no-op으로 규정하는 이유(호출자 방어 로직 생략 가능)를 붙이면 더 좋습니다. [nice]

### Add
- 추가 없음. 억지로 늘리지 않습니다.

### Risks
- 없음. `ctx`가 이미 취소됐을 때 `WithTimeout`이 즉시 만료되는 동작은 표준이며 계약과 일치합니다.

---

## After

```go
// Package tunnel implements the reverse gRPC tunnel from an in-cluster agent
// to the control plane. It moves opaque bytes and deliberately does not depend
// on client-go: parsing apiserver responses is the caller's job, not the
// tunnel's.
package tunnel

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// ErrClosed is returned by Send after the session has been closed. Callers
// should treat it as terminal and re-dial rather than retrying on the same
// session.
var ErrClosed = errors.New("tunnel: session closed")

// Session is a single multiplexed connection to the control plane. A Session
// is safe for concurrent use by multiple goroutines.
type Session struct {
	stream grpcStream
	// deadline bounds a single Send; it is not the session lifetime.
	deadline time.Duration
}

// Send forwards one frame to the control plane and blocks until the frame is
// acknowledged or ctx is done. It returns ErrClosed if the session was closed
// concurrently, or a wrapped context error on deadline.
//
// A zero-length payload is a no-op so callers can forward drained buffers
// without a length guard.
func (s *Session) Send(ctx context.Context, payload []byte) error {
	if len(payload) == 0 {
		return nil
	}
	ctx, cancel := context.WithTimeout(ctx, s.deadline)
	defer cancel()

	if err := s.stream.SendMsg(ctx, payload); err != nil {
		return fmt.Errorf("tunnel: send frame: %w", err)
	}
	return nil
}
```
