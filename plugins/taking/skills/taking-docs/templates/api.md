# <서비스> API

<!-- 채우기: H1은 API 이름. "<서비스> API". -->

## Overview

<!-- 채우기: 무슨 API인가. base URL, 버전, 포맷. 표 권장. -->
| 항목 | 값 |
| --- | --- |
| Base URL | `<https://.../api/v1>` |
| 포맷 | `application/json` |
| 버전 | `<v1>` |

## Auth

<!-- 채우기: 인증 방식. 표로. -->
| 방식 | 위치 | 값 |
| --- | --- | --- |
| `<Bearer token>` | `Authorization` 헤더 | `Bearer <token>` |

## Endpoints

<!-- 채우기: 엔드포인트 목록은 반드시 표. -->
| Method | Path | 설명 | 인증 |
| --- | --- | --- | --- |
| `GET` | `<endpoint>` | `<설명>` | ✅ |
| `POST` | `<endpoint>` | `<설명>` | ✅ |

## Request / Response

<!-- 채우기: 필드는 표. 완결 문장 X, 속성으로. -->
### Request

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `<field>` | `string` | ✅ | `<설명>` |

### Response

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `<field>` | `string` | `<설명>` |

## Errors

<!-- 채우기: 에러 코드는 반드시 표. -->
| HTTP | code | 의미 | 조치 |
| --- | --- | --- | --- |
| `400` | `<INVALID_ARG>` | `<의미>` | `<조치>` |
| `401` | `<UNAUTHENTICATED>` | `<의미>` | `<조치>` |
| `404` | `<NOT_FOUND>` | `<의미>` | `<조치>` |

## Examples

```bash
curl -X POST "<Base URL>/<endpoint>" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"<field>": "<value>"}'
```

```json
{
  "<field>": "<value>"
}
```

## References

- [<OpenAPI / 스펙>](<경로>)
