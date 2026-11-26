# python : Python 주석, docstring 규칙

공통 규칙은 [common.md](common.md), 정본은 [../style-guide.md](../style-guide.md). 여기는 Python에서만 나오는 것만 적습니다. PEP 257(docstring)과 PEP 8(주석) 관례를 따릅니다.

## 목차

- 형식
- 타입 힌트가 말하는 것은 적지 않습니다
- docstring 스타일은 저장소를 따릅니다
- 반드시 문서화
- 적지 않을 것
- 예

## 형식

| 상황 | 형태 |
| --- | --- |
| 산문 설명 | `#`. 인라인 주석은 코드와 두 칸 띄움(PEP 8) |
| 공개 모듈, 클래스, 함수 | `"""..."""` docstring. 선언 바로 아래 첫 문장이 요약 |
| 한 줄 docstring | `"""한 줄 요약입니다."""` 같은 줄에 닫음 |
| 여러 줄 docstring | 요약 한 줄, 빈 줄, 상세 |

docstring 첫 줄은 그 객체가 무엇인지로 요약합니다(PEP 257). WHAT을 풀어쓰기보다 계약과 WHY를 먼저 둡니다.

## 타입 힌트가 말하는 것은 적지 않습니다

타입 힌트가 있으면 파라미터, 반환의 종류를 docstring이 반복하지 않습니다. 타입에 없는 제약, 단위, 부작용만 남깁니다(TS JSDoc과 같은 원칙).

```python
# Bad: 타입 힌트가 말하는 것을 docstring이 반복
def fetch(cluster_id: str, size: int) -> list[Resource]:
    """
    Args:
        cluster_id (str): 클러스터 식별자
        size (int): 페이지 크기
    Returns:
        list[Resource]: 자원 목록
    """

# Good: 타입에 없는 계약만
def fetch(cluster_id: str, size: int) -> list[Resource]:
    """`size`는 계약 상한이 100입니다. 넘겨 보내면 서버가 400을 돌려줍니다."""
```

## docstring 스타일은 저장소를 따릅니다

Google, NumPy, reStructuredText 세 가지가 흔합니다. 어느 쪽이 맞다기보다 한 저장소 안에서 섞지 않는 것이 중요합니다. 이미 쓰는 스타일이 있으면 그것을 따릅니다(규칙 1, DRY).

| 스타일 | 표식 | 도구 |
| --- | --- | --- |
| Google | `Args:`, `Returns:`, `Raises:` | Sphinx napoleon |
| NumPy | `Parameters` 아래 밑줄 | Sphinx napoleon |
| reST | `:param:`, `:returns:`, `:raises:` | Sphinx 기본 |

```python
# Good: 저장소가 Google 스타일이면 Raises로 예외 계약을 적습니다
def publish(event: Event) -> int:
    """이벤트를 tenant 토픽에 보내고 broker offset을 돌려줍니다.

    전송은 at-least-once이므로 소비자는 eventId로 중복을 걸러야 합니다.

    Raises:
        PublishError: broker가 거부하거나 ack이 시간 초과일 때.
    """
```

## 반드시 문서화

코드에서 안 보이고, 모르면 잘못 고치는 것들입니다.

| 상황 | 남길 사실 |
| --- | --- |
| 가변 기본 인자 회피 | `def f(x=None)` 뒤 `x = x or []`인 이유. `[]`를 기본값에 두면 호출 사이에 공유됨 |
| 예외 계약 | 어떤 조건에 어떤 예외가 오는지(checked 개념이 없어 docstring이 유일한 계약) |
| None이 오는 반환 | 반환 타입에 `None`이 포함될 때 언제 None인지 |
| 제너레이터, 지연 평가 | 호출 시점이 아니라 소비 시점에 I/O, 예외가 나는 경우 |
| 전역 상태, 싱글턴 | 모듈 import 시 실행되는 부작용 |
| `__slots__`, 메타클래스 | 평범한 클래스처럼 고치면 깨지는 제약 |
| 동시성 | GIL이 지켜 주지 않는 자리(멀티프로세싱, C 확장, async 취소) |

## 적지 않을 것

- 타입 힌트를 풀어쓴 docstring(`:param x: int형 x`).
- 문법 해설(`i += 1  # i를 1 늘림`).
- 함수명을 그대로 옮긴 요약(`"""process를 수행합니다."""`).
- 걷어낸 구현의 회고. 커밋 메시지가 갖습니다.

## 예

```python
# Bad: 문법 해설 + 함수명 재진술
def check_age(age: int) -> bool:
    """나이를 확인합니다."""
    # 만약 나이가 19세 미만이라면
    if age < 19:
        return False
    return True

# Good: 코드에 없는 WHY만. 짧은 사실은 명사형으로 끊습니다
def check_age(age: int) -> bool:
    # 청소년보호법 기준 만 19세 미만 필터링 (가족 계정 예외 없음)
    if age < 19:
        return False
    return True
```

```python
# Good: 가변 기본 인자를 피한 이유
def append_tag(tag: str, tags: list[str] | None = None) -> list[str]:
    # 기본값에 []를 두면 호출 사이에 공유되어 이전 tag가 남습니다
    tags = tags or []
    tags.append(tag)
    return tags
```
