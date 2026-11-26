#!/usr/bin/env bash
# 주석 규칙 위반을 기계로 찾는다. 규칙은 code-comments/style-guide.md.
#
# 정규식으로 판정할 수 있는 것만 본다. 설계 서사, WHAT 재진술 같은 판단이 필요한 위반은
# 사람이나 리뷰가 잡는다(review-guide.md).
#
# 사용: lint-comments.sh [경로...]        기본값은 현재 디렉터리
#       lint-comments.sh --quiet [경로]   must-fix만 출력
#
# 종료 코드: must-fix가 있으면 1, 없으면 0(should/nice는 0)
set -uo pipefail

QUIET=0
if [ "${1-}" = "--quiet" ]; then QUIET=1; shift; fi
TARGETS=("${@:-.}")

# 주석 줄로 볼 접두사. 언어별 형태를 한 패턴에 담는다.
COMMENT='^\s*(//|\*|/\*|\{/\*|#)'
GLOBS=(-g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '*.go' -g '*.java' -g '*.py'
       -g '!*/generated/*' -g '!*/gen/*' -g '!node_modules' -g '!*.pb.go')

fail=0
found=0

report() { # 심각도 규칙 설명
  local sev="$1" rule="$2" desc="$3"
  [ "$QUIET" = 1 ] && [ "$sev" != "must-fix" ] && return 0
  printf '\n[%s] %s — %s\n' "$sev" "$rule" "$desc"
}

hits() { # rg 결과가 있으면 출력하고 건수를 반환
  local n
  n=$(wc -l <<<"$1" | tr -d ' ')
  [ -z "$1" ] && return 1
  sed 's/^/  /' <<<"$1"
  found=$((found + n))
  return 0
}

# ── 종결 톤 (규칙 25) — 저장소 다수 톤을 먼저 세고 소수 쪽만 잡는다.
# 존댓말로 통일된 저장소를 전량 위반으로 내면 관례를 지킨 코드가 오류가 된다(§0 프로젝트 우선).
hon=$(rg -c --no-heading "${GLOBS[@]}" "$COMMENT.*(합니다|됩니다|습니다|하십시오|주십시오)" "${TARGETS[@]}" 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
dec=$(rg -c --no-heading "${GLOBS[@]}" "$COMMENT.*(한다|된다|없다|이다)\.?\s*(\*/)?\s*$" "${TARGETS[@]}" 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
if [ "$hon" -gt 0 ] && [ "$dec" -gt 0 ]; then
  if [ "$hon" -ge "$dec" ]; then
    out=$(rg -n --no-heading "${GLOBS[@]}" "$COMMENT.*(한다|된다|없다|이다)\.?\s*(\*/)?\s*$" "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
    report should "종결 톤 혼재" "이 저장소 관례는 존댓말(${hon}건)이다. 평서체 ${dec}건을 맞춘다."
  else
    out=$(rg -n --no-heading "${GLOBS[@]}" "$COMMENT.*(합니다|됩니다|습니다|하십시오|주십시오)" "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
    report should "종결 톤 혼재" "이 저장소 관례는 평서체(${dec}건)이다. 존댓말 ${hon}건을 맞춘다."
  fi
  hits "$out"
elif [ "$hon" -gt 0 ] && [ "$dec" -eq 0 ]; then
  report nice "존댓말 통일" "저장소가 존댓말로 통일돼 있다(${hon}건). 관례이므로 그대로 둔다."
fi

# ── 가운뎃점 — AI 문체 표시. 쉼표로 바꾼다(style-guide §17).
# 링크 표시 텍스트 `[제목·부제](경로)` 안의 것은 고유명사라 제외한다.
mid=$(rg -n --no-heading "${GLOBS[@]}" "$COMMENT.*·" "${TARGETS[@]}" 2>/dev/null | rg -v '\]\(' | cut -c1-160)
if [ -n "$mid" ]; then
  report should "가운뎃점" "나열은 쉼표로 쓴다. 셋 이상이면 표나 불릿으로 바꾼다."
  hits "$mid"
fi

# ── must-fix: 독자가 못 푸는 참조 (COMMENT_GUIDE 언어 절)
out=$(rg -n --no-heading "${GLOBS[@]}" "$COMMENT.*(§[0-9]|ADR-[0-9X]{3,})" "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
if [ -n "$out" ]; then
  report must-fix "못 푸는 참조" "재번호되는 섹션 번호, 내부 ADR 코드. 문장으로 자립시킨다."
  hits "$out"; fail=1
fi

# ── should: 저자 회고 어투 (규칙 24)
# 낱말 목록만으로는 놓친다('그랬다', '드로어였다', '가능해졌다'가 실제로 빠져나갔다).
# 주석의 과거형 어미가 회고를 가장 잘 잡는다 — 지금 코드를 설명하는 주석은 과거형을 쓸 일이 없다.
out=$(rg -n --no-heading "${GLOBS[@]}" \
  "$COMMENT.*(로 옮겼다|걷어냈|만들어 봤|실제로 겪었|해 봤고|봤고 )" "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
if [ -n "$out" ]; then
  report should "저자 회고" "결정의 배경은 커밋, 문서로. 소스에는 잘못 고치게 막는 사실만."
  hits "$out"
fi

# ── should: 과거형 어미 (규칙 24) — 회고이거나 지난 상태 서술이다
out=$(rg -n --no-heading "${GLOBS[@]}" \
  "$COMMENT.*(었다|였다|았다|졌다)(\)|\.|,| |$)" "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
if [ -n "$out" ]; then
  report should "과거형 어미" "회고(예전에는 …였다)인지 본다. 런타임 상태 서술(요청이 오지 않았다)은 정당하다."
  hits "$out"
fi

# ── should: 80자 초과 주석 줄 (규칙 23)
#
# awk의 length()는 로케일에 따라 바이트를 세, 한글(3바이트)이면 40자에도 걸린다.
# 문자 수로 재야 하므로 python에 맡긴다.
out=$(rg -n --no-heading "${GLOBS[@]}" "$COMMENT" "${TARGETS[@]}" 2>/dev/null \
  | python3 -c '
import sys
for line in sys.stdin:
    head, _, body = line.rstrip("\n").partition(":")
    lineno, _, code = body.partition(":")
    if len(code) > 80:
        print(f"{head}:{lineno}:{code[:120]}")
')
if [ -n "$out" ]; then
  report should "80자 초과" "한 줄은 80자 이내로 끊는다."
  hits "$out"
fi

# ── should: 5줄 초과 블록 주석 (규칙 23)
out=$(
  for f in $(rg -l "${GLOBS[@]}" '/\*' "${TARGETS[@]}" 2>/dev/null); do
    awk -v F="$f" '
      /\/\*/ && !inb { inb=1; start=NR; n=0 }
      inb { n++ }
      inb && /@(param|returns?|throws|example)/ { api=1 }
      /\*\// && inb { if (n > 5 && !api) printf "%s:%d: 블록 주석 %d줄\n", F, start, n; inb=0; api=0 }
    ' "$f"
  done | cut -c1-160
)
if [ -n "$out" ]; then
  report should "긴 블록 주석" "5줄을 넘기면 설명을 문서로 옮기고 요약만 남긴다(예외: architecture, security, protocol, concurrency)."
  hits "$out"
fi

# ── nice: TS, JS에서 JSDoc 아닌 블록 주석 (관례)
out=$(rg -n --no-heading -g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '!*/generated/*' \
  '^\s*/\*([^*]|$)' "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
if [ -n "$out" ]; then
  report nice "비-JSDoc 블록 주석" "TS, JS에서 산문 설명은 // 가 관례다."
  hits "$out"
fi

# ── nice: bare TODO/FIXME (규칙 13)
out=$(rg -n --no-heading "${GLOBS[@]}" '(TODO|FIXME)([^(:]|$)' "${TARGETS[@]}" 2>/dev/null | cut -c1-160)
if [ -n "$out" ]; then
  report nice "bare TODO" "TODO(이름 또는 #이슈): 형식으로 남긴다."
  hits "$out"
fi

echo
if [ "${found:-0}" = 0 ]; then
  echo "위반 없음"
else
  echo "총 ${found:-0}건 (must-fix가 있으면 종료 코드 1)"
fi
exit "${fail:-0}"
