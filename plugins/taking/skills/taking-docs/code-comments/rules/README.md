# rules : 언어와 도메인별 주석 규칙

정본은 [../style-guide.md](../style-guide.md)입니다. 여기는 그 언어나 도메인에서만 나오는 것을 담습니다. 먼저 `common.md` 를 보고, 대상 언어와 도메인 파일을 더 봅니다.

| 파일 | 언제 |
| --- | --- |
| [common.md](common.md) | 언제나. 언어와 도메인을 가리지 않는 규칙 |
| [go.md](go.md) | Go. GoDoc 은 식별자 이름으로 시작하는 완전한 문장 |
| [java.md](java.md) | Java. 공개 API 는 JavaDoc 으로 계약 명시 |
| [typescript.md](typescript.md) | TypeScript, JavaScript, React |
| [python.md](python.md) | Python. PEP 257 docstring, 타입 힌트 반복 금지, 예외 계약 |
| [rust.md](rust.md) | Rust. rustdoc `# Safety`/`# Errors`/`# Panics`, `Send`/`Sync`, doctest |
| [grpc.md](grpc.md) | `.proto` 의 service, rpc 주석. 스트리밍, 데드라인, 멱등성, 에러 매핑 |
| [protobuf.md](protobuf.md) | proto 필드와 메시지 주석. 필드 번호, reserved, oneof, enum zero-value |
| [kafka.md](kafka.md) | 토픽과 이벤트 계약. 엔벨로프, 파티션 키, 순서, 전달 시맨틱, DLQ |
| [kubernetes.md](kubernetes.md) | CRD 와 컨트롤러. 필드 의미, reconcile 가정, RBAC 의도 |
