# package 템플릿

패키지, 모듈의 목적과 **경계**를 설명합니다. 핵심은 "이 패키지가 의도적으로 하지 않는 것"을 적어 잘못된 의존을 막는 것입니다.

## 왜/언제

- **언제**: 새 패키지, 모듈을 만들 때, 또는 경계가 모호해 오용이 생길 때.
- **왜**: 패키지 doc은 아키텍처 계약입니다. "무엇을 하지 않는가"가 "무엇을 하는가"보다 오용을 더 많이 막습니다(예: tunnel이 apiserver 응답을 파싱하지 않음).
- **관례**: Go는 패키지당 `doc.go` 하나에 몰아 씁니다(DRY). Java는 `package-info.java`.

## 스켈레톤 (Go `doc.go`)

```go
// Package <name> <한 문장 목적>.
//
// <경계: 이 패키지가 책임지는 범위. 어떤 계층에 속하는가>.
//
// This package intentionally does not <하지 않는 것과 그 이유>.
// <그 책임은 어느 패키지가 지는지 지목>.
package <name>
```

## 스켈레톤 (Java `package-info.java`)

```java
/**
 * <한 문장 목적>.
 *
 * <경계: 책임 범위, 계층>.
 *
 * <p>This package intentionally does not <하지 않는 것과 이유>; that concern
 * belongs to {@link <다른.package>}.
 */
package <fully.qualified.name>;
```

## Good example (Go)

```go
// Package tunnel implements the reverse gRPC tunnel between a cluster agent
// and the control plane. It multiplexes logical streams over one connection
// and reconnects with backoff.
//
// It sits below the API layer: it moves opaque bytes and knows nothing about
// their meaning.
//
// This package intentionally does not depend on client-go and does not parse
// apiserver responses. Interpreting payloads is the caller's job; keeping the
// tunnel payload-agnostic lets it carry non-Kubernetes traffic unchanged.
package tunnel
```

## Good example (Java)

```java
/**
 * Domain events for cluster lifecycle changes, serialized to the shared Kafka
 * topics. Defines the event schema and the mapping to wire records.
 *
 * <p>This package intentionally does not open Kafka connections or manage
 * offsets; transport and delivery guarantees belong to {@link
 * com.innogrid.xpu.messaging.transport}. Keeping schema separate from
 * transport lets the same events flow over a test in-memory bus.
 */
package com.innogrid.xpu.cluster.event;
```
