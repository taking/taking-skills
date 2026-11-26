# good-typescript : TS, React 파일 리뷰

흔한 TS, React 주석 문제를 담은 파일을 리뷰합니다. Before에는 걷어낸 구현 회고, 마크업 재진술, WHY 없는 주석이 섞여 있습니다 → Review로 걸러내고 → After는 계약과 WHY만 남깁니다.

포인트: deps 배열 제외 이유, `replace` vs `push`, globals.css `!important` 우회, 회고 docstring 제거.

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

```tsx
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

/**
 * 자원 목록 패널.
 *
 * 직접 만든 테이블을 걷어내고 TanStack Table로 바꿨습니다. Safari에서 열 너비가
 * 1px씩 어긋나 끝까지 고생했습니다.
 */
export function ResourcePanel({ clusterId }: { clusterId: string }) {
  const [params, setParams] = useSearchParams()
  const [settling, setSettling] = useState(false)
  const installedNames = useInstalled(clusterId)

  // installedNames는 뺍니다
  useEffect(() => {
    const id = setInterval(() => poll(clusterId), 3000)
    return () => clearInterval(id)
  }, [settling])

  // 탭을 바꿉니다
  function selectTab(tab: string) {
    const next = new URLSearchParams(params)
    next.set('tab', tab)
    setParams(next, { replace: true })
  }

  return (
    <div className="flex flex-col gap-2">
      {/* 위: 제목, 아래: 목록 */}
      <span className="text-xs">{clusterId}</span>
      <ResourceTable names={installedNames} onTab={selectTab} />
    </div>
  )
}
```

## Review

폴링과 라우팅 코드 자체는 정확합니다. 주석이 문제입니다. 회고, 마크업 재진술, 함수명 재진술이 잡음이고, 정작 모르면 깨뜨릴 세 자리(deps 제외, `replace`, `span`)에는 WHY가 없거나 빈약합니다.

### Improve Code
- 변경 없음. `clearInterval` 정리와 `URLSearchParams` 복사는 정확합니다.

### Improve Naming
- 변경 없음. `settling`, `selectTab`, `installedNames` 모두 의도가 드러납니다.

### Remove
- 컴포넌트 docstring 두 번째 문단(걷어낸 테이블 회고): 지금 없는 구현의 이야기입니다. git 이력이 갖습니다. [should]
- `{/* 위: 제목, 아래: 목록 */}`: 마크업이 이미 말합니다. [should]
- `// 탭을 바꿉니다`: 함수명 `selectTab` 재진술. [should]

### Rewrite
- `// installedNames는 뺍니다`: 뺐다는 사실(WHAT)만 있고 왜 뺐는지가 없습니다. 넣으면 매 조회마다 effect가 다시 돌아 폴링이 멈추지 않는다는 WHY로 바꿉니다. [must-fix]

### Add
- `setParams(next, { replace: true })`에 WHY가 없습니다. `push`로 "정리"하면 탭 전환이 이력에 쌓여 뒤로가기가 목록이 아니라 앞 탭으로 갑니다. 한 줄 추가. [should]
- `<span className="text-xs">`: globals.css가 `p`를 15px로 강제해 `span`을 쓴 것이라면, 모르면 `p`로 바꿔 화면이 깨집니다. 근거 한 줄 추가. [should]

### Risks
- 폴링 간격 `3000`이 상수가 아니라 리터럴입니다. 원천이 비싼 경로면 근거를 남길 자리입니다. 지금은 정보가 부족해 제안만. [nice]

---

## After

```tsx
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

/** 자원 목록 패널. */
export function ResourcePanel({ clusterId }: { clusterId: string }) {
  const [params, setParams] = useSearchParams()
  const [settling, setSettling] = useState(false)
  const installedNames = useInstalled(clusterId)

  // `installedNames`를 넣으면 매 조회마다 effect가 다시 돌아 폴링이 멈추지 않습니다.
  useEffect(() => {
    const id = setInterval(() => poll(clusterId), 3000)
    return () => clearInterval(id)
  }, [settling])

  function selectTab(tab: string) {
    const next = new URLSearchParams(params)
    next.set('tab', tab)
    // push면 탭 전환이 이력에 쌓여 뒤로가기가 목록이 아니라 앞 탭으로 갑니다.
    setParams(next, { replace: true })
  }

  return (
    <div className="flex flex-col gap-2">
      {/* globals.css가 `p`를 15px, weight 400으로 강제하므로 span에 둡니다 */}
      <span className="text-xs">{clusterId}</span>
      <ResourceTable names={installedNames} onTab={selectTab} />
    </div>
  )
}
```
