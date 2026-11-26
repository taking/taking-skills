# templates : 문서 종류별 시작 틀

새 문서를 쓸 때 해당하는 틀을 골라 복사합니다. 각 파일은 H1 형식과 채울 절을 주석으로 담고 있습니다. 틀의 절을 다 채우려고 없는 내용을 지어내지 않습니다. 해당하지 않는 절은 뺍니다.

요구, 제약, 계약을 담는 틀(api, grpc, kafka, security, architecture)은 문서 머리에 `이 문서를 읽는 법`을 두고 요구 표에 `수준` 열을 둡니다. 수준 키워드의 정본은 [../reference/requirement-levels.md](../reference/requirement-levels.md)를 가리키고, 키워드 표를 각 문서에 중복해 넣지 않습니다.

| 파일 | 언제 |
| --- | --- |
| [overview.md](overview.md) | 주제 하나를 소개하는 개요 |
| [architecture.md](architecture.md) | 컴포넌트 구조와 책임 |
| [design.md](design.md) | 기능 하나의 설계 |
| [adr.md](adr.md) | 결정과 그 근거 기록 |
| [api.md](api.md) | REST API 레퍼런스 |
| [grpc.md](grpc.md) | gRPC 서비스 레퍼런스 |
| [kafka.md](kafka.md) | 이벤트 도메인과 토픽 계약 |
| [communication.md](communication.md) | 두 시스템 사이의 통신 흐름 |
| [security.md](security.md) | 신뢰 경계와 보안 가정 |
| [runbook.md](runbook.md) | 운영 작업 절차 |
| [troubleshooting.md](troubleshooting.md) | 증상에서 원인까지의 진단 |
| [repo-readme.md](repo-readme.md) | 저장소 설치와 실행 안내 |
| [postmortem.md](postmortem.md) | 장애 회고(사후 분석) |

작업 보고서는 여기가 아니라 [../reference/work-report.md](../reference/work-report.md)가 가집니다.
