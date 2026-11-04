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
t  "스킬 7개"                     test "$(ls "$d/.agents/skills" | wc -l)" -eq 7
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

# 9. preflight는 읽기 전용
d="$W/pre"; mkdir -p "$d"
t  "preflight 실행"               bash -c "cd '$d' && bash '$KIT/scripts/preflight.sh'"
t  "preflight 후 비어 있음"       test -z "$(ls -A "$d")"

echo "PASS $PASS / FAIL $FAIL"
[ $FAIL -eq 0 ]
