# templates : 주석 틀

계약을 적어야 하는 자리의 틀입니다. 틀의 항목을 다 채우려고 없는 계약을 지어내지 않습니다. 규칙은 [../style-guide.md](../style-guide.md), 언어별 관례는 [../rules/](../rules/README.md)입니다.

| 파일 | 대상 |
| --- | --- |
| [godoc.md](godoc.md) | Go 공개 함수와 타입 |
| [javadoc.md](javadoc.md) | Java 공개 메서드와 클래스 |
| [package.md](package.md) | 패키지와 모듈의 목적, 경계, 의도적으로 하지 않는 것 |
| [interface.md](interface.md) | 인터페이스 계약. 사전조건, 사후조건, 불변식, thread-safety |
| [concurrency.md](concurrency.md) | 락이 보호하는 것, 소유권, 락 순서, 취소 |
| [security.md](security.md) | 신뢰 경계, 인증과 권한, 입력 검증, 민감 데이터 |
| [grpc.md](grpc.md) | gRPC service 와 RPC 의 wire 계약 |
| [kubernetes.md](kubernetes.md) | CRD 필드와 컨트롤러 |
