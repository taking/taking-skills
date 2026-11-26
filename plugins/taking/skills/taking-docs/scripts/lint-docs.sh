#!/usr/bin/env bash
# Markdown 문서의 문체 위반을 기계로 찾는다. 규칙은 ../style-guide.md, 점검은 ../checklist.md.
#
# 정규식으로 판정할 수 있는 것만 본다. 번역투, 어색한 흐름, 설계 서사처럼 판단이 필요한 위반은
# 사람이 잡는다. 종결 톤은 저장소마다 다르므로 세어서 알려만 주고 실패로 보지 않는다.
#
# 코드 블록 안, 인라인 코드, 인용문은 보지 않는다. 규칙 문서가 "쓰지 말 것" 예시를 그 셋에 넣어
# 두기 때문에, 빼지 않으면 규칙 문서 자신이 위반으로 잡힌다. 펜스는 CommonMark 규칙을 따라
# 여는 펜스보다 같거나 긴 것만 닫는 것으로 본다(4중 백틱 안의 3중 백틱을 바르게 다룬다).
#
# 사용: lint-docs.sh [경로...]         기본값은 현재 디렉터리
#       lint-docs.sh --quiet [경로]    must-fix만 출력
#
# 종료 코드: must-fix가 있으면 1, 없으면 0
set -uo pipefail

QUIET=0
if [ "${1-}" = "--quiet" ]; then QUIET=1; shift; fi
TARGETS=("${@:-.}")

fail=0
found=0

FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(
  find "${TARGETS[@]}" -type f -name '*.md' \
    -not -name '_*' -not -path '*/node_modules/*' -not -path '*/vendor/*' 2>/dev/null | sort)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "대상 .md 파일이 없다"
  exit 0
fi

# 펜스를 추적하는 공통 조각. fence는 열린 펜스의 길이, fch는 그 문자다.
FENCE_AWK='
  function fence_line(   m, f, n, ch) {
    if (match($0, /^[ \t]*(`{3,}|~{3,})/) == 0) return 0
    f = substr($0, RSTART, RLENGTH); gsub(/[ \t]/, "", f)
    n = length(f); ch = substr(f, 1, 1)
    if (fence == 0) { fence = n; fch = ch; fopen = FNR; frest = substr($0, RSTART + RLENGTH); return 1 }
    if (ch == fch && n >= fence) { fence = 0; return 2 }
    return 3
  }
'

# 본문만 모은다. 코드 블록 안을 빼고, 인라인 코드는 자리만 남긴다.
PROSE=$(awk "$FENCE_AWK"'
  FNR == 1 { fence = 0; frontmatter = ($0 == "---") }
  frontmatter {
    if (FNR > 1 && $0 == "---") frontmatter = 0
    next
  }
  { r = fence_line(); if (r) next }
  fence { next }
  { line = $0; gsub(/`[^`]*`/, "`CODE`", line); print FILENAME ":" FNR ":" line }
' "${FILES[@]}")

report() { printf '\n[%s] %s : %s\n' "$1" "$2" "$3"; }

emit() { # 심각도 규칙 설명 결과
  local sev="$1" rule="$2" desc="$3" out="$4" n
  out=$(sed '/^$/d' <<<"$out")
  [ -z "$out" ] && return 0
  n=$(wc -l <<<"$out" | tr -d ' ')
  report "$sev" "$rule" "$desc"
  cut -c1-200 <<<"$out" | sed 's/^/  /'
  found=$((found + n))
  [ "$sev" = must-fix ] && fail=1
  return 0
}

scan() { # 심각도 규칙 설명 패턴 [제외패턴]
  local sev="$1" rule="$2" desc="$3" pat="$4" skip="${5-}" out
  [ "$QUIET" = 1 ] && [ "$sev" != "must-fix" ] && return 0
  out=$(grep -E "$pat" <<<"$PROSE")
  [ -n "$skip" ] && out=$(grep -Ev "$skip" <<<"$out")
  emit "$sev" "$rule" "$desc" "$out"
}

# 인용문은 인용한 예시라 문서 자신의 문장이 아니다.
QUOTED=':[0-9]+:[ \t]*>'

# ── AI가 쓴 글의 표시 (style-guide 8.1, 8.2, 8.5)
scan must-fix "가운뎃점" "나열은 쉼표로 쓴다. 셋을 넘으면 표나 불릿으로." '·' "\]\(|$QUOTED"
scan must-fix "긴 대시" "마침표, 콜론, 괄호로 바꾼다. 표의 빈칸 표시는 예외." '—' "\|[ \t]*—[ \t]*\||$QUOTED"
scan should "부정 대구" "거부절을 지우고 뒤쪽을 동작이나 수치로 직접 쓴다." '단순[히한] .{1,20}(가|이) 아니라' "$QUOTED"
scan should "곡선 따옴표" "곧은 따옴표로 바꾼다. 워드프로세서 복붙 흔적." '[“”‘’]' "$QUOTED"

# ── 포장만 하는 말 (style-guide 8)
scan should "AI 문체" "실제 동작이나 수치로 바꾸거나 지운다." \
  '(이를 통해|이로써|다음과 같다|효율적으로|손쉽게|원활하게|수행한다|지원한다|제공한다|다양한 )' "$QUOTED"
scan should "모호어" "구체 조건이나 수치로 바꾼다." \
  '(적절히|필요시|일반적으로|최대한|가능한 경우|아마도)' "$QUOTED"

# ── 지어낸 말 (style-guide 8.4). 사람 판단이 필요해 should로 둔다.
scan should "지어낸 추상 명사" "묶어 부르지 말고 나열하거나 평범한 말을 쓴다." \
  '(표면|출구를|접합부|정의처|결절점|층위|귀결)' "$QUOTED"
scan should "어려운 동사" "쉬운 말로 바꾼다. 치환한다는 바꾼다, 봉합한다는 메운다." \
  '(관통한|귀속한|치환한|봉합한)' "$QUOTED"
scan should "조어 후보" "저장소에 이미 쓰는 말인지 세어 본다." '(스네이크 케이스|영대문자 스네이크)' "$QUOTED"

# ── 정보 없는 선언문 (style-guide 8, 8.3)
scan must-fix "빈 선언문" "무엇을 어떻게 하는지 쓰거나 지운다." \
  '(의도된 설계|경계는 명확|단일한 기준을 제공|일관된 방향성|구조적 일관성)' "$QUOTED"
scan should "의의 과장" "사실만 쓰고 독자가 판단하게 둔다." \
  '(의 핵심이자|의 정수|을 상징한다|중요한 전환점|라는 점에서 의미가)' "$QUOTED"

# ── 문장 부호와 나열 (style-guide 8.1)
scan should "리스트 리드인" "마침표로 끝내거나 명사구 뒤에 콜론을 둔다." '다:$' "$QUOTED"

# ── 하드랩 (style-guide 2). 한 문단은 한 줄이므로 문단 안에 둘 이상의 줄이 있으면 손으로 끊은 것이다.
emit must-fix "하드랩" "문단 안에서 줄을 끊지 않는다. 한 문단은 한 줄로 쓴다." "$(
  awk -F: '
    { file = $1; ln = $2; txt = substr($0, length(file) + length(ln) + 3) }
    file != pf { run = 0; pf = file }
    txt ~ /^\|/ || txt ~ /^#/ || txt ~ /^[ \t]*>/ || txt ~ /^[ \t]*$/ \
      || txt ~ /^[ \t]*<!--/ || txt ~ /^[ \t]*(-{3,}|\*{3,}|_{3,})[ \t]*$/ { run = 0; next }
    txt ~ /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { start = ln; first = txt; run = 1; next }
    { if (run == 0) { start = ln; first = txt }
      run++
      if (run == 2) print file ":" start ":" first }
  ' <<<"$PROSE"
)"

# ── 코드 블록 언어 누락. 바깥 펜스만 본다.
emit must-fix "코드 블록 언어 누락" "go, yaml, bash, json, text, markdown 중 하나를 지정한다." "$(
  awk "$FENCE_AWK"'
    FNR == 1 { fence = 0 }
    { r = fence_line(); if (r == 1 && frest ~ /^[ \t]*$/) print FILENAME":"FNR":"$0 }
  ' "${FILES[@]}"
)"

# ── 제목 계층 건너뜀 (style-guide 9)
if [ "$QUIET" = 0 ]; then
  emit should "제목 계층 건너뜀" "## 다음에 #### 를 두지 않는다." "$(
    awk -F: '
      { file = $1; ln = $2; txt = substr($0, length(file) + length(ln) + 3) }
      file != pf { prev = 0; pf = file }
      txt ~ /^#+ / { n = index(txt, " ") - 1
        if (prev && n > prev + 1) print file ":" ln ":" txt
        prev = n }
    ' <<<"$PROSE"
  )"
fi

# ── 깨진 상대 링크 (style-guide 10). 외부 URL은 대상 파일이 없으므로 보지 않는다.
out=""
for f in "${FILES[@]}"; do
  d=$(dirname "$f")
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    case "$t" in http://*|https://*|mailto:*) continue ;; esac
    [ -e "$d/${t%%#*}" ] || out+="$f : $t"$'\n'
  done < <(awk "$FENCE_AWK"'
      FNR == 1 { fence = 0 }
      { r = fence_line(); if (r) next }
      fence { next }
      { line = $0; gsub(/`[^`]*`/, "", line); print line }
    ' "$f" 2>/dev/null | grep -oE '\]\([^)]+\.md(#[^)]*)?\)' | sed -E 's/^\]\(//; s/\)$//')
done
emit must-fix "깨진 링크" "대상 파일이 없다." "$out"

# ── 종결 톤. 저장소 관례가 우선이라 세어서 알려만 준다.
if [ "$QUIET" = 0 ]; then
  hon=$(grep -cE '(합니다|입니다|습니다)' <<<"$PROSE")
  dec=$(grep -cE '(한다|된다|없다|이다)\.?[ \t]*$' <<<"$PROSE")
  printf '\n[참고] 종결 톤 : 존댓말 %s줄, 평서체 %s줄. 한 문서 안에서 섞지 않고 저장소 다수를 따른다.\n' "$hon" "$dec"
fi

echo
if [ "$found" = 0 ]; then
  echo "위반 없음"
else
  echo "총 ${found}건 (must-fix가 있으면 종료 코드 1)"
fi
exit "$fail"
