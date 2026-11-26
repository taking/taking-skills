# taking-skills

개인 Claude Code 스킬을 플러그인 마켓플레이스로 배포합니다. 여러 머신에서 `claude plugin`으로 설치해 쓰고, 한 플러그인(`taking`)에 여러 스킬을 번들로 담습니다.

## 수록 스킬

| 스킬 | 호출 | 설명 |
| --- | --- | --- |
| `taking-docs` | `/taking:taking-docs` | 한국어 기술 문서와 코드 주석을 자연스럽고 정확하게 작성하고 검토합니다. README, 설계 문서, ADR, API 문서, GoDoc, JavaDoc, JSDoc, 커밋 메시지, PR 본문에 적용하고, 번역투와 AI 문체를 제거합니다. |

## 설치

### 셸에서

```bash
# 1. 마켓플레이스 등록 (최초 1회)
claude plugin marketplace add taking/taking-skills

# 2. 플러그인 설치
claude plugin install taking@taking-skills --scope user
```

### 세션 안에서

```text
/plugin marketplace add taking/taking-skills
/plugin install taking@taking-skills
```

### 설치 범위

| scope | 적용 범위 | 저장 위치 |
| --- | --- | --- |
| `user` | 모든 프로젝트 (기본 권장) | 사용자 설정 |
| `project` | 현재 프로젝트만 | 프로젝트 설정 |

설치 후 실행 중인 세션에서는 `/reload-plugins`를 실행하거나 Claude Code를 재시작해야 명령이 활성화됩니다.

## 사용법

호출하면 스킬 규칙이 로드되어 그 턴의 작업에 적용됩니다.

```text
/taking:taking-docs            # 규칙을 적용해 작업 진행
/taking:taking-docs <작업>     # 특정 작업 유형으로 바로 진행
```

### 작업 유형

| 작업 | 하는 일 |
| --- | --- |
| `write` | 문서 종류와 독자를 확인하고 템플릿을 골라 새 문서를 작성합니다. |
| `review` | 정확성, 논리, 구조, 문체 순으로 문제를 찾고 필요한 부분만 고칩니다. |
| `rewrite` | 원문의 사실과 값을 보존하며 문단, 표, 다이어그램으로 재구성합니다. |
| `polish` | 작성자 말투와 사실을 보존하고 AI 문체와 번역투만 다듬습니다. 수정본, 주요 수정 사항, 확인이 필요한 부분으로 보고합니다. |
| `work report` | 작업 메모를 Jira 댓글, MR 본문, 작업 완료 보고서로 재구성합니다. |
| `code comment review` | 코드 개선 가능성을 먼저 보고 주석을 유지, 삭제, 재작성, 추가합니다. |

### 예시

```text
/taking:taking-docs polish
이 회고 초안 다듬어줘: (본문)

/taking:taking-docs review
README.md 검토해줘

/taking:taking-docs
이 PR 본문 작성해줘
```

### 린트 스크립트

규칙 위반을 정규식으로 찾는 보조 스크립트가 포함됩니다. 설치 경로는 아래 `claude plugin list`로 확인합니다.

```bash
# 설치 경로 확인
claude plugin list

# Markdown 형식과 문체 검사
<플러그인 경로>/skills/taking-docs/scripts/lint-docs.sh <경로>

# 코드 주석 검사
<플러그인 경로>/skills/taking-docs/scripts/lint-comments.sh <경로>
```

## 관리

```bash
claude plugin list                          # 설치된 플러그인과 경로
claude plugin update taking@taking-skills   # 최신으로 갱신 (이후 /reload-plugins)
claude plugin uninstall taking@taking-skills
claude plugin marketplace remove taking-skills
```

## 개발

구조:

```text
taking-skills/
├── .claude-plugin/
│   └── marketplace.json     # 카탈로그 (name, owner, plugins[])
└── plugins/
    └── taking/
        ├── .claude-plugin/
        │   └── plugin.json  # 플러그인 매니페스트 (name, description, version)
        └── skills/
            └── taking-docs/ # 스킬 본문 (SKILL.md 외)
```

스킬을 추가하려면 `plugins/taking/skills/<이름>/SKILL.md`를 만듭니다. 한 플러그인이 여러 스킬을 담습니다.

푸시 전 검증:

```bash
claude plugin validate ./plugins/taking    # 매니페스트와 구조 검사
claude --plugin-dir ./plugins/taking       # 로컬에서 바로 띄워 확인
```

수정한 뒤에는 커밋하고 푸시한 다음, 설치한 머신에서 `claude plugin update taking@taking-skills`로 갱신합니다.
