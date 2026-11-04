#!/usr/bin/env bash
# cofa-kit 설치기. 과제 폴더(작업 루트)에서 실행한다. 키트 원본은 /tmp/kit 같은 과제 밖에 둔다.
#
#   bash /tmp/kit/install.sh                    기본 설치 (규칙 + 키트 스킬 9개 + 양식)
#   bash /tmp/kit/install.sh --extras core,web  외부 스킬 묶음도 설치 (vendor/SOURCES.md)
#   bash /tmp/kit/install.sh --check            쓰지 않고 무엇을 할지만 출력 (충돌 있으면 exit 1)
#   bash /tmp/kit/install.sh --remove           규칙 블록과 수정 안 된 스킬 제거 (작업 문서는 남김)
#   옵션: --target DIR (기본: 현재 폴더)
#
# --extras 값 (쉼표로 여러 개): core, web, all, stageshow, 또는 vendor/skills 아래 스킬 이름
#   core = verification-before-completion systematic-debugging test-driven-development ponytail incremental-implementation
#   web  = webapp-testing frontend-design frontend-ui-engineering fixing-accessibility security-and-hardening
#   stageshow = 공개 GitHub에서 고정 커밋을 /tmp/kit-extras 로 clone (이 옵션만 네트워크 사용)
#
# 하는 일
#   - AGENTS.md(있으면 AGENTS.override.md)에 시작·끝 표식이 있는 블록으로 규칙을 병합
#   - .agents/skills/ 에 스킬 복사
#   - docs/ 작업 양식, AI_COLLABORATION.md, HOW_TO_USE.md, scripts/verify.sh, scripts/e2e.py, .gitignore는
#     같은 이름이 없을 때만 생성 (있으면 그대로 둠)
# 하지 않는 일: 패키지 설치, 전역 설정(~/.codex 등) 수정, 기존 파일 덮어쓰기, git 커밋.
# 충돌(같은 경로에 다른 내용의 키트 관리 파일)이 하나라도 있으면 아무것도 쓰지 않고 중단한다.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PWD"
MODE=install
EXTRAS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check)  MODE=check ;;
    --remove) MODE=remove ;;
    --target) TARGET="$2"; shift ;;
    --extras) EXTRAS="$2"; shift ;;
    --extras=*) EXTRAS="${1#--extras=}" ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 64 ;;
  esac
  shift
done
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$KIT_DIR" ] || [ "${TARGET#"$KIT_DIR"/}" != "$TARGET" ]; then
  echo "중단: 키트 폴더 안이 아니라 과제 폴더에서 실행하세요 (현재: $TARGET)" >&2; exit 64
fi
[ "$TARGET" = "${HOME:-/nonexistent}" ] && echo "주의: 홈 폴더에 설치합니다. 과제 폴더가 맞는지 확인하세요."

BEGIN='<!-- cofa-kit:begin -->'
END='<!-- cofa-kit:end -->'
RULES="$KIT_DIR/AGENTS.md"
SKILLS=(kickoff interview ux plan slice e2e verify collab-log wrapup)
CORE=(verification-before-completion systematic-debugging test-driven-development ponytail incremental-implementation)
WEB=(webapp-testing frontend-design frontend-ui-engineering fixing-accessibility security-and-hardening)
VENDOR_ALL=("${CORE[@]}" "${WEB[@]}")
STAGESHOW_SRC="${KIT_STAGESHOW_DIR:-/tmp/kit-extras/stageshow}"

# ---------- extras 해석 ----------
PICK=(); WANT_STAGESHOW=0
add_pick() { local x; for x in "${PICK[@]+"${PICK[@]}"}"; do [ "$x" = "$1" ] && return 0; done; PICK+=("$1"); }
IFS=',' read -r -a _ex <<< "$EXTRAS"
for e in "${_ex[@]+"${_ex[@]}"}"; do
  e="${e// /}"
  case "$e" in
    "") ;;
    core) for s in "${CORE[@]}"; do add_pick "$s"; done ;;
    web)  for s in "${WEB[@]}"; do add_pick "$s"; done ;;
    all)  for s in "${VENDOR_ALL[@]}"; do add_pick "$s"; done ;;
    stageshow) WANT_STAGESHOW=1 ;;
    *) if [ -f "$KIT_DIR/vendor/skills/$e/SKILL.md" ]; then add_pick "$e"
       else echo "알 수 없는 extras: $e (vendor/SOURCES.md 참고)" >&2; exit 64; fi ;;
  esac
done

if [ -f "$TARGET/AGENTS.override.md" ]; then AG="$TARGET/AGENTS.override.md"; else AG="$TARGET/AGENTS.md"; fi

# 관리 대상(충돌 검사): "원본|대상" — 파일 또는 디렉터리
MANAGED=()
for s in "${SKILLS[@]}"; do MANAGED+=("$KIT_DIR/.agents/skills/$s/SKILL.md|$TARGET/.agents/skills/$s/SKILL.md"); done
for s in "${PICK[@]+"${PICK[@]}"}"; do MANAGED+=("$KIT_DIR/vendor/skills/$s|$TARGET/.agents/skills/$s"); done
[ $WANT_STAGESHOW -eq 1 ] && MANAGED+=("$KIT_DIR/extras/stageshow/SKILL.md|$TARGET/.agents/skills/stageshow/SKILL.md")
# 보존 대상(없을 때만 생성)
KEEP=(
  "$KIT_DIR/templates/TASK.md|$TARGET/docs/TASK.md"
  "$KIT_DIR/templates/DECISIONS.md|$TARGET/docs/DECISIONS.md"
  "$KIT_DIR/templates/FAILURE_MODES.md|$TARGET/docs/FAILURE_MODES.md"
  "$KIT_DIR/templates/HANDOFF.md|$TARGET/docs/HANDOFF.md"
  "$KIT_DIR/templates/SCREENS.md|$TARGET/docs/SCREENS.md"
  "$KIT_DIR/templates/AI_COLLABORATION.md|$TARGET/AI_COLLABORATION.md"
  "$KIT_DIR/templates/HOW_TO_USE.md|$TARGET/HOW_TO_USE.md"
  "$KIT_DIR/templates/gitignore|$TARGET/.gitignore"
  "$KIT_DIR/scripts/verify_template.sh|$TARGET/scripts/verify.sh"
  "$KIT_DIR/scripts/e2e_template.py|$TARGET/scripts/e2e.py"
)

rel() { printf '%s' "${1#"$TARGET"/}"; }
same() { if [ -d "$1" ]; then diff -rq "$1" "$2" >/dev/null 2>&1; else cmp -s "$1" "$2"; fi; }
current_block() { awk -v b="$BEGIN" -v e="$END" '$0==b{f=1;next} $0==e{exit} f' "$AG"; }
count_line() { grep -cxF -- "$1" "$AG" 2>/dev/null || true; }

# ---------- 제거 ----------
if [ "$MODE" = remove ]; then
  if [ -f "$AG" ] && [ "$(count_line "$BEGIN")" = 1 ] && [ "$(count_line "$END")" = 1 ]; then
    tmp="$(mktemp)"
    awk -v b="$BEGIN" -v e="$END" '$0==b{f=1;next} $0==e{f=0;next} !f' "$AG" > "$tmp"
    if grep -q '[^[:space:]]' "$tmp"; then cat "$tmp" > "$AG"; echo "제거   $(rel "$AG") 규칙 블록"
    else rm -f "$AG"; echo "삭제   $(rel "$AG") (블록만 있던 파일)"; fi
    rm -f "$tmp"
  elif [ -f "$AG" ] && grep -qF 'cofa-kit:' "$AG"; then
    echo "건너뜀 $(rel "$AG") 표식 짝이 맞지 않아 직접 정리 필요"
  fi
  ALL_MANAGED=()
  for s in "${SKILLS[@]}"; do ALL_MANAGED+=("$KIT_DIR/.agents/skills/$s/SKILL.md|$TARGET/.agents/skills/$s/SKILL.md"); done
  for s in "${VENDOR_ALL[@]}"; do ALL_MANAGED+=("$KIT_DIR/vendor/skills/$s|$TARGET/.agents/skills/$s"); done
  ALL_MANAGED+=("$KIT_DIR/extras/stageshow/SKILL.md|$TARGET/.agents/skills/stageshow/SKILL.md")
  for pair in "${ALL_MANAGED[@]}"; do
    src="${pair%%|*}"; dst="${pair#*|}"
    [ -e "$dst" ] || continue
    if same "$src" "$dst"; then
      if [ -d "$dst" ]; then rm -r -- "${dst:?}"; else rm -f -- "$dst"; rmdir "$(dirname "$dst")" 2>/dev/null || true; fi
      echo "삭제   $(rel "$dst")"
    else
      echo "남김   $(rel "$dst") (수정됨)"
    fi
  done
  rmdir "$TARGET/.agents/skills" "$TARGET/.agents" 2>/dev/null || true
  echo "작업 문서(docs/, AI_COLLABORATION.md, HOW_TO_USE.md, scripts/, .gitignore)는 남겨 둡니다."
  exit 0
fi

# ---------- 상태 판단 ----------
CONFLICTS=0; PLAN=()
nb=$( [ -f "$AG" ] && count_line "$BEGIN" || echo 0 )
ne=$( [ -f "$AG" ] && count_line "$END" || echo 0 )
if [ "$nb" = 0 ] && [ "$ne" = 0 ]; then BLOCK=absent
elif [ "$nb" = 1 ] && [ "$ne" = 1 ]; then
  if diff -q <(current_block) "$RULES" >/dev/null; then BLOCK=same; else BLOCK=differs; fi
else BLOCK=broken
fi
case "$BLOCK" in
  absent)  PLAN+=("병합   $(rel "$AG") 에 규칙 블록 추가") ;;
  same)    PLAN+=("유지   $(rel "$AG") 규칙 블록 (이미 같음)") ;;
  differs) PLAN+=("충돌   $(rel "$AG") 규칙 블록 내용이 키트와 다름 (--remove 후 재설치)"); CONFLICTS=$((CONFLICTS+1)) ;;
  broken)  PLAN+=("충돌   $(rel "$AG") 시작·끝 표식이 짝이 맞지 않음 (직접 정리 필요)"); CONFLICTS=$((CONFLICTS+1)) ;;
esac
for pair in "${MANAGED[@]}"; do
  src="${pair%%|*}"; dst="${pair#*|}"
  if [ ! -e "$dst" ]; then PLAN+=("생성   $(rel "$dst")")
  elif same "$src" "$dst"; then PLAN+=("유지   $(rel "$dst") (이미 같음)")
  else PLAN+=("충돌   $(rel "$dst") 내용이 다름"); CONFLICTS=$((CONFLICTS+1))
  fi
done
for pair in "${KEEP[@]}"; do
  dst="${pair#*|}"
  if [ -e "$dst" ]; then PLAN+=("보존   $(rel "$dst") (기존 파일 그대로)"); else PLAN+=("생성   $(rel "$dst")"); fi
done
if [ $WANT_STAGESHOW -eq 1 ]; then
  if [ -f "$STAGESHOW_SRC/SKILL.md" ]; then PLAN+=("유지   $STAGESHOW_SRC (stageshow 원본, 과제 폴더 밖)")
  else PLAN+=("받기   $STAGESHOW_SRC (stageshow 원본, GitHub clone, 과제 폴더 밖)"); fi
fi

kit_rev="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
printf '%s\n' "${PLAN[@]}"
if [ "$MODE" = check ]; then
  echo "확인 모드: 아무것도 쓰지 않았습니다. 충돌 $CONFLICTS 건."
  [ $CONFLICTS -eq 0 ] || exit 1
  exit 0
fi
if [ $CONFLICTS -gt 0 ]; then
  echo "중단: 충돌 $CONFLICTS 건. 아무것도 쓰지 않았습니다." >&2; exit 1
fi

# ---------- 설치 ----------
if [ $WANT_STAGESHOW -eq 1 ] && [ ! -f "$STAGESHOW_SRC/SKILL.md" ]; then
  bash "$KIT_DIR/scripts/fetch_stageshow.sh" "$STAGESHOW_SRC" || { echo "중단: stageshow를 받지 못했습니다. 아무것도 쓰지 않았습니다." >&2; exit 1; }
fi
if [ "$BLOCK" = absent ]; then
  if [ -s "$AG" ]; then
    [ -n "$(tail -c1 "$AG")" ] && printf '\n' >> "$AG"
    printf '\n' >> "$AG"
  fi
  { printf '%s\n' "$BEGIN"; cat "$RULES"; printf '%s\n' "$END"; } >> "$AG"
fi
for pair in "${MANAGED[@]}" "${KEEP[@]}"; do
  src="${pair%%|*}"; dst="${pair#*|}"
  [ -e "$dst" ] && continue
  mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ]; then cp -R "$src" "$dst"; else cp "$src" "$dst"; fi
done
chmod +x "$TARGET/scripts/verify.sh" "$TARGET/scripts/e2e.py" 2>/dev/null || true

n_sk=$(( ${#SKILLS[@]} + ${#PICK[@]} + WANT_STAGESHOW ))
cat <<EOF
설치 완료: 스킬 ${n_sk}개 (키트 커밋 $kit_rev — AI_COLLABORATION.md '사용한 공개 자료'에 적으세요)
다음:
  1. git add -A && git commit -m "chore: cofa-kit 설치 ($kit_rev)"
  2. Codex를 이 폴더에서 새로 연다 (이미 열린 세션에는 스킬이 반영되지 않음)
  3. /status 와 /skills 로 확인. 안 보이면 ".agents/skills/kickoff/SKILL.md 읽고 따라"
  4. \$kickoff 시작 HH:MM, 과제 마감 HH:MM   (프롬프트 모음: cat $KIT_DIR/docs/prompts/README.md)
끄기: bash $KIT_DIR/install.sh --remove
EOF
