# rust (Rust 문화 규칙)

rustdoc, Rust API Guidelines 관례. 공개 항목은 `///`로 문서화하고, 섹션 제목(`# Safety`, `# Errors`, `# Panics`)으로 계약을 나눕니다.

---

## 목차

- 1. `///`는 바깥 문서, `//!`는 안쪽 문서
- 2. `unsafe` 함수는 `# Safety`로 호출 전제를 적습니다
- 3. `# Errors`, `# Panics`로 실패 계약을 적습니다
- 4. `Send`/`Sync` 보장을 문서화합니다
- 5. intra-doc 링크로 타입을 참조합니다
- 6. `# Examples`는 doctest로 검증합니다
- 7. 타입이 말하는 것을 다시 적지 않습니다

## 1. `///`는 바깥 문서, `//!`는 안쪽 문서

`///`는 뒤에 오는 항목(함수, 타입)을, `//!`는 그것을 감싼 항목(모듈, 크레이트)을 문서화합니다. 모듈 목적과 경계는 파일 맨 위 `//!`에 둡니다.

```rust
// Bad: 모듈 설명을 첫 함수 위 `///`에 달면 함수 문서로 붙습니다
/// 역방향 gRPC 터널. 바이트만 옮기고 apiserver 응답은 파싱하지 않습니다.
pub fn dial(id: ClusterId) -> Session { ... }

// Good: 모듈 문서는 `//!`로 파일 상단에
//! 역방향 gRPC 터널. 바이트만 옮기고 apiserver 응답은 파싱하지 않습니다.

/// clusterId에 묶인 Session을 엽니다. 반환된 Session의 Close 책임은 호출자에게 있습니다.
pub fn dial(id: ClusterId) -> Session { ... }
```

## 2. `unsafe` 함수는 `# Safety`로 호출 전제를 적습니다

`unsafe fn`은 컴파일러가 검증하지 못하는 전제를 호출자가 지켜야 합니다. 그 전제를 `# Safety`에 적지 않으면 호출자는 무엇을 보장해야 하는지 알 수 없습니다. 고위험 코드는 style-guide §17을 따릅니다.

```rust
// Bad: 무엇을 지켜야 안전한지 없음
pub unsafe fn from_raw(ptr: *mut u8, len: usize) -> Buf

// Good: 호출자가 지킬 전제를 명시
/// # Safety
///
/// `ptr`는 `len` 바이트만큼 한 번에 할당된 영역을 가리켜야 하고, Buf가 살아 있는
/// 동안 다른 곳에서 해제하면 안 됩니다. 해제 책임은 Buf로 넘어갑니다.
pub unsafe fn from_raw(ptr: *mut u8, len: usize) -> Buf
```

## 3. `# Errors`, `# Panics`로 실패 계약을 적습니다

`Result`를 반환하면 어떤 조건에서 어떤 에러가 오는지 `# Errors`에 적습니다. panic 가능성이 있으면 `# Panics`로 조건을 밝혀, 호출자가 미리 검증하게 합니다.

```rust
// Bad: 에러 종류도 panic 조건도 숨겨짐
pub fn send(&self, frame: &[u8]) -> Result<Offset, SendError>

// Good: 분기할 에러와 panic 조건을 계약으로
/// # Errors
///
/// 세션이 동시에 닫히면 [`SendError::Closed`]를 반환합니다. 호출자는 재시도 대신
/// 새 세션으로 다시 연결해야 합니다.
///
/// # Panics
///
/// `frame`이 64 KiB를 넘으면 panic합니다. 프레임 크기는 호출 전에 맞춥니다.
pub fn send(&self, frame: &[u8]) -> Result<Offset, SendError>
```

## 4. `Send`/`Sync` 보장을 문서화합니다

타입을 스레드 간에 넘기거나 공유할 수 있는지는 계약입니다. 자동 도출을 `!Send`로 끊거나, 공유 안전성의 근거가 자명하지 않으면 적습니다.

```rust
// Bad: 왜 공유해도 되는지 근거 없음
pub struct Registry { inner: Mutex<HashMap<ClusterId, Session>> }

// Good: 무엇이 무엇을 지키는지와 공유 계약(Send + Sync)
/// 여러 스레드가 공유해도 안전합니다. 모든 변경은 `inner`의 Mutex를 지나며,
/// 락을 쥔 채로 네트워크 호출을 하면 전 세션이 직렬화되니 금지합니다.
pub struct Registry { inner: Mutex<HashMap<ClusterId, Session>> }

// Good: 자동 Send를 의도적으로 끊는 이유(!Send)
/// 이 핸들은 생성한 스레드에서만 써야 합니다. 내부 포인터가 thread-local 아레나를
/// 가리켜, 다른 스레드로 넘기면 아레나보다 오래 삽니다.
pub struct ArenaHandle { /* ... */ }
```

## 5. intra-doc 링크로 타입을 참조합니다

문서에서 다른 항목을 가리킬 때 평문 대신 `[Type]`, `[Type::method]`를 씁니다. 이름이 바뀌거나 사라지면 `cargo doc`이 깨진 링크를 잡아 줍니다.

```rust
// Bad: 평문 참조. 이름이 바뀌어도 아무도 모릅니다
/// 실패하면 SendError를 반환합니다. reconnect로 다시 엽니다.

// Good: intra-doc 링크
/// 실패하면 [`SendError`]를 반환합니다. [`Session::reconnect`]로 다시 엽니다.
```

## 6. `# Examples`는 doctest로 검증합니다

`# Examples`의 코드 블록은 `cargo test`가 함께 돌립니다. 설명용 예제도 컴파일되고 실행되므로, 시그니처가 바뀌면 어긋난 예제를 바로 잡아냅니다. 실행은 빼고 컴파일만 할 때는 `no_run`, 컴파일도 건너뛸 때는 `ignore`로 의도를 밝힙니다.

```rust
/// 주어진 cluster에 연결합니다.
///
/// # Examples
///
/// ```
/// let s = Session::dial(ClusterId::new("c1"))?;
/// assert_eq!(s.send(b"ping")?.as_u64(), 0);
/// # Ok::<(), DialError>(())
/// ```
pub fn dial(id: ClusterId) -> Result<Session, DialError>
```

## 7. 타입이 말하는 것을 다시 적지 않습니다

시그니처가 이미 말하는 파라미터 종류, 반환 타입을 산문으로 반복하지 않습니다. 타입에 없는 제약, 단위, 소유권만 남깁니다.

```rust
// Bad: 타입을 산문으로 반복
/// clusterId(ClusterId)를 받아 Session을 반환합니다.
pub fn dial(id: ClusterId) -> Session

// Good: 타입에 없는 계약만
/// 반환된 Session의 Close 책임은 호출자에게 있습니다. Drop은 로그만 남기고 막지 않습니다.
pub fn dial(id: ClusterId) -> Session
```
