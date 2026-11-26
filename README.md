# taking-skills

개인 Claude Code 스킬을 플러그인 마켓플레이스로 배포합니다.

## 수록 스킬

| 스킬 | 설명 |
| --- | --- |
| `taking-docs` | 한국어 기술 문서와 코드 주석을 자연스럽고 정확하게 작성·검토합니다. README, 설계 문서, ADR, API 문서, GoDoc/JavaDoc/JSDoc, 커밋 메시지, PR 본문에 적용합니다. |

## 설치

```bash
# 마켓플레이스 등록
claude plugin marketplace add taking/taking-skills

# 플러그인 설치 (사용자 범위)
claude plugin install taking@taking-skills --scope user
```

세션 안에서는 `/plugin marketplace add taking/taking-skills` → `/plugin install taking@taking-skills`로도 됩니다.

설치 후 호출:

```
/taking:taking-docs
```

## 업데이트

```bash
claude plugin update taking@taking-skills
```

세션에서는 이어서 `/reload-plugins`.

## 개발

구조:

```
taking-skills/
├── .claude-plugin/
│   └── marketplace.json     # 카탈로그
└── plugins/
    └── taking/
        ├── .claude-plugin/
        │   └── plugin.json  # 플러그인 매니페스트
        └── skills/
            └── taking-docs/ # 스킬 본문 (SKILL.md 등)
```

푸시 전 검증:

```bash
claude plugin validate ./plugins/taking
claude --plugin-dir ./plugins/taking   # 로컬에서 바로 띄워 확인
```

스킬을 추가하려면 `plugins/taking/skills/<이름>/SKILL.md`를 만들고 새 스킬 디렉터리를 둡니다. 한 플러그인이 여러 스킬을 번들로 담습니다.
