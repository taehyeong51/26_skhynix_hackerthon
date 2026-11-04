#!/usr/bin/env bash
# install.sh / verify_template.sh 오프라인 테스트. 임시 폴더만 쓴다.
# 사용: bash tests/test_install.sh
set -u
KIT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "ok   $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
t() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
nt() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$name"; else ok "$name"; fi; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
inst() { (cd "$1" && bash "$KIT/install.sh" "${@:2}"); }

# 1. 빈 폴더 설치
d="$W/empty"; mkdir -p "$d"
t  "빈 폴더 설치 성공"            inst "$d"
t  "AGENTS.md 생성"               test -f "$d/AGENTS.md"
t  "스킬 9개 (extras 없음)"       test "$(ls "$d/.agents/skills" | wc -l)" -eq 9
t  "docs/SCREENS.md 생성"         test -f "$d/docs/SCREENS.md"
t  "e2e.py 생성"                  test -x "$d/scripts/e2e.py"
t  ".gitignore 생성"              grep -q node_modules "$d/.gitignore"
t  "docs/TASK.md 생성"            test -f "$d/docs/TASK.md"
t  "산출물 뼈대 2종"              test -f "$d/AI_COLLABORATION.md" -a -f "$d/HOW_TO_USE.md"
t  "verify.sh 실행 권한"          test -x "$d/scripts/verify.sh"
t  "키트 docs 미복사"             test ! -e "$d/docs/RUNBOOK.md"
t  "재설치는 변화 없음"           inst "$d"
t  "블록 한 번만"                 test "$(grep -c 'cofa-kit:begin' "$d/AGENTS.md")" -eq 1

# 2. 기존 AGENTS.md·산출물 보존
d="$W/existing"; mkdir -p "$d"
printf '# 과제 규칙\n원래 내용\n' > "$d/AGENTS.md"
printf '내가 쓴 문서\n' > "$d/HOW_TO_USE.md"
t  "기존 파일 있는 폴더 설치"     inst "$d"
t  "기존 AGENTS 내용 보존"        grep -q '원래 내용' "$d/AGENTS.md"
t  "블록 병합됨"                  grep -q 'cofa-kit:end' "$d/AGENTS.md"
t  "HOW_TO_USE 덮어쓰지 않음"     grep -q '내가 쓴 문서' "$d/HOW_TO_USE.md"

# 3. override 우선
d="$W/override"; mkdir -p "$d"; printf '# override\n' > "$d/AGENTS.override.md"
t  "override 폴더 설치"           inst "$d"
t  "override에 블록"              grep -q 'cofa-kit:begin' "$d/AGENTS.override.md"
t  "AGENTS.md는 만들지 않음"      test ! -e "$d/AGENTS.md"

# 4. 충돌이면 아무것도 쓰지 않음
d="$W/conflict"; mkdir -p "$d/.agents/skills/plan"; printf 'mine\n' > "$d/.agents/skills/plan/SKILL.md"
nt "충돌 시 설치 실패"            inst "$d"
t  "충돌 시 AGENTS.md 미생성"     test ! -e "$d/AGENTS.md"
t  "충돌 시 다른 스킬 미생성"     test ! -e "$d/.agents/skills/kickoff"
nt "--check도 충돌 보고(exit 1)"  inst "$d" --check

# 5. --check는 쓰지 않음
d="$W/check"; mkdir -p "$d"
t  "--check 성공"                 inst "$d" --check
t  "--check 후 비어 있음"         test -z "$(ls -A "$d")"

# 6. --remove
d="$W/remove"; mkdir -p "$d"; printf '# 과제\n' > "$d/AGENTS.md"
inst "$d" >/dev/null 2>&1
printf '\n메모\n' >> "$d/docs/TASK.md"
t  "--remove 성공"                inst "$d" --remove
nt "블록 제거"                    grep -q 'cofa-kit' "$d/AGENTS.md"
t  "원래 AGENTS 내용 유지"        grep -q '# 과제' "$d/AGENTS.md"
t  "스킬 제거"                    test ! -e "$d/.agents"
t  "작업 문서 유지"               grep -q '메모' "$d/docs/TASK.md"
d="$W/remove2"; mkdir -p "$d"; inst "$d" >/dev/null 2>&1; inst "$d" --remove >/dev/null 2>&1
t  "블록만 있던 AGENTS.md 삭제"   test ! -e "$d/AGENTS.md"

# 7. 키트 폴더 안에서 실행 거부
nt "키트 폴더 안 설치 거부"       inst "$KIT"

# 8. verify_template.sh
d="$W/verify"; mkdir -p "$d/scripts"; cp "$KIT/scripts/verify_template.sh" "$d/scripts/verify.sh"
(cd "$d" && bash scripts/verify.sh >/dev/null 2>&1); rc=$?
t  "검사 0건이면 exit 2"          test $rc -eq 2
sed -i 's|^# ===== 검사 목록.*|&\ncheck "참" true|' "$d/scripts/verify.sh"
(cd "$d" && bash scripts/verify.sh >/dev/null 2>&1); rc=$?
t  "통과만 있으면 exit 0"         test $rc -eq 0
sed -i 's|^check "참" true|&\ncheck "거짓" false|' "$d/scripts/verify.sh"
(cd "$d" && bash scripts/verify.sh >/dev/null 2>&1); rc=$?
t  "실패 있으면 exit 1"           test $rc -eq 1
mkdir -p "$d/tests"
nt "unittest 0건은 실패"          bash -c "source <(sed -n '/^tests_ran()/,/^}/p' '$d/scripts/verify.sh'); cd '$d' && tests_ran python3 -m unittest discover -s tests"

# 9. --extras
d="$W/extras"; mkdir -p "$d"
t  "--extras core,web 설치"       inst "$d" --extras core,web
t  "스킬 19개"                    test "$(ls "$d/.agents/skills" | wc -l)" -eq 19
t  "ux 스킬과 UI 외부 스킬"       test -f "$d/.agents/skills/ux/SKILL.md" -a -f "$d/.agents/skills/frontend-ui-engineering/LICENSE"
t  "vendor 원문 그대로"           diff -rq "$KIT/vendor/skills/systematic-debugging" "$d/.agents/skills/systematic-debugging"
t  "vendor LICENSE 동봉"          test -f "$d/.agents/skills/ponytail/LICENSE" -a -f "$d/.agents/skills/webapp-testing/LICENSE.txt"
t  "extras 재설치 변화 없음"      inst "$d" --extras all
nt "알 수 없는 extras 거부"       inst "$d" --extras nope
printf 'x\n' >> "$d/.agents/skills/ponytail/SKILL.md"
nt "vendor 수정본은 충돌"         inst "$d" --extras core
t  "--remove (extras 포함)"       inst "$d" --remove
t  "수정 안 된 vendor 삭제"       test ! -e "$d/.agents/skills/systematic-debugging"
t  "수정한 vendor는 남김"         test -f "$d/.agents/skills/ponytail/SKILL.md"
d="$W/single"; mkdir -p "$d"
t  "스킬 이름으로 하나만"         inst "$d" --extras webapp-testing
t  "하나만 설치됨"                test "$(ls "$d/.agents/skills" | wc -l)" -eq 10
# stageshow: 네트워크 없이 미리 받아 둔 폴더로 확인
s="$W/fake-stageshow"; mkdir -p "$s"; printf -- '---\nname: stageshow\n---\n' > "$s/SKILL.md"
d="$W/stage"; mkdir -p "$d"
t  "--extras stageshow (원본 있음)" env KIT_STAGESHOW_DIR="$s" bash -c "cd '$d' && bash '$KIT/install.sh' --extras stageshow"
t  "stageshow 연결 스킬만 과제에" test -f "$d/.agents/skills/stageshow/SKILL.md" -a ! -e "$d/.agents/skills/stageshow/kit"
d="$W/stage-check"; mkdir -p "$d"
t  "stageshow --check는 받지 않음" env KIT_STAGESHOW_DIR="$W/none" bash -c "cd '$d' && bash '$KIT/install.sh' --extras stageshow --check | grep -q '받기'"
t  "stageshow --check 후 비어 있음" test -z "$(ls -A "$d")" -a ! -e "$W/none"

# 10. e2e.py: playwright가 없으면 exit 3 (미실행)
if ! python3 -c 'import playwright' 2>/dev/null; then
  python3 "$KIT/scripts/e2e_template.py" >/dev/null 2>&1; rc=$?
  t "e2e playwright 없음 → exit 3" test $rc -eq 3
fi
d="$W/v-e2e"; mkdir -p "$d/scripts"; cp "$KIT/scripts/verify_template.sh" "$d/scripts/verify.sh"
printf '#!/bin/sh\nexit 3\n' > "$d/scripts/e2e.py"
sed -i 's|^# ===== 검사 목록.*|&\ncheck "참" true\ncheck_e2e "E2E"|' "$d/scripts/verify.sh"
sed -i 's|python3 scripts/e2e.py|sh scripts/e2e.py|' "$d/scripts/verify.sh"
out=$(cd "$d" && bash scripts/verify.sh 2>&1); rc=$?
t  "check_e2e exit 3 → SKIP"      bash -c "test $rc -eq 0 && printf '%s' \"\$1\" | grep -q 'SKIP | E2E'" _ "$out"

# 10b. 단계별 프롬프트 문서
P="$KIT/docs/prompts"
for f in 00-setup 01-kickoff 02-interview 03-plan 04-first-e2e 05-iterate 06-stuck 07-midcheck 08-freeze 09-submit S1-handoff S2-study-tab; do
  t "프롬프트 $f 존재·구조" bash -c "f='$P/$f.md'; test -f \"\$f\" && grep -q '^## 언제' \"\$f\" && grep -q '^## 프롬프트' \"\$f\" && grep -q '^## 정상이면' \"\$f\" && grep -q '^## 아니면' \"\$f\" && grep -q '^## 다음' \"\$f\""
done
t  "프롬프트 인덱스가 모든 단계 파일을 가리킴" bash -c "cd '$P' && for f in [0-9]*.md S[0-9]-*.md; do grep -q \"(\${f%.md}.md)\" README.md || { echo missing \$f; exit 1; }; done"
t  "프롬프트의 \$스킬 이름이 실제 스킬" bash -c "
  names=\$(grep -ohE '\\\$[a-z][a-z-]+' '$P'/*.md | tr -d '\$' | sort -u)
  for n in \$names; do
    [ -f '$KIT/.agents/skills/'\$n'/SKILL.md' ] || [ -f '$KIT/vendor/skills/'\$n'/SKILL.md' ] || [ -f '$KIT/extras/'\$n'/SKILL.md' ] || { echo \"없는 스킬: \$n\"; exit 1; }
  done"
t  "프롬프트의 문서 링크가 유효" bash -c "cd '$P' && for l in \$(grep -ohE '\\]\\(\\.\\./[A-Za-z_]+\\.md\\)' *.md | sed -E 's/\\]\\((.*)\\)/\\1/' | sort -u); do test -f \"\$l\" || { echo broken \$l; exit 1; }; done"
t  "옛 PROMPTS.md 참조 없음"       bash -c "! grep -rq 'PROMPTS.md' '$KIT' --exclude-dir=.git --exclude-dir=vendor --exclude=test_install.sh"

# 11. preflight는 읽기 전용
d="$W/pre"; mkdir -p "$d"
t  "preflight 실행"               bash -c "cd '$d' && bash '$KIT/scripts/preflight.sh'"
t  "preflight 후 비어 있음"       test -z "$(ls -A "$d")"

echo "PASS $PASS / FAIL $FAIL"
[ $FAIL -eq 0 ]
