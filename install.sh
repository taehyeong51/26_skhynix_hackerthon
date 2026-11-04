#!/usr/bin/env bash
# cofa-kit 설치기. 과제 폴더(작업 루트)에서 실행한다. 키트 원본은 /tmp/kit 같은 과제 밖에 둔다.
#
#   bash /tmp/kit/install.sh            설치
#   bash /tmp/kit/install.sh --check    쓰지 않고 무엇을 할지만 출력 (충돌 있으면 exit 1)
#   bash /tmp/kit/install.sh --remove   AGENTS 블록과 키트 스킬 제거 (작업 문서는 남김)
#   옵션: --target DIR (기본: 현재 폴더)
#
# 하는 일
#   - AGENTS.md(있으면 AGENTS.override.md)에 시작·끝 표식이 있는 블록으로 규칙을 병합
#   - .agents/skills/<7개>/SKILL.md 복사
#   - docs/TASK.md 등 작업 양식, AI_COLLABORATION.md·HOW_TO_USE.md, scripts/verify.sh는
#     같은 이름이 없을 때만 생성 (있으면 그대로 둠)
# 하지 않는 일: 네트워크 접속, 전역 설정(~/.codex 등) 수정, 기존 파일 덮어쓰기.
# 충돌(같은 경로에 다른 내용의 키트 관리 파일)이 하나라도 있으면 아무것도 쓰지 않고 중단한다.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PWD"
MODE=install
while [ $# -gt 0 ]; do
  case "$1" in
    --check)  MODE=check ;;
    --remove) MODE=remove ;;
    --target) TARGET="$2"; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
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
SKILLS=(kickoff interview plan slice verify collab-log wrapup)
RULES="$KIT_DIR/AGENTS.md"

if [ -f "$TARGET/AGENTS.override.md" ]; then AG="$TARGET/AGENTS.override.md"; else AG="$TARGET/AGENTS.md"; fi

# 관리 파일(충돌 검사 대상): "원본|대상"
MANAGED=()
for s in "${SKILLS[@]}"; do MANAGED+=("$KIT_DIR/.agents/skills/$s/SKILL.md|$TARGET/.agents/skills/$s/SKILL.md"); done
# 보존 파일(없을 때만 생성): "원본|대상"
KEEP=(
  "$KIT_DIR/templates/TASK.md|$TARGET/docs/TASK.md"
  "$KIT_DIR/templates/DECISIONS.md|$TARGET/docs/DECISIONS.md"
  "$KIT_DIR/templates/FAILURE_MODES.md|$TARGET/docs/FAILURE_MODES.md"
  "$KIT_DIR/templates/HANDOFF.md|$TARGET/docs/HANDOFF.md"
  "$KIT_DIR/templates/AI_COLLABORATION.md|$TARGET/AI_COLLABORATION.md"
  "$KIT_DIR/templates/HOW_TO_USE.md|$TARGET/HOW_TO_USE.md"
  "$KIT_DIR/scripts/verify_template.sh|$TARGET/scripts/verify.sh"
)

rel() { printf '%s' "${1#"$TARGET"/}"; }
current_block() { awk -v b="$BEGIN" -v e="$END" '$0==b{f=1;next} $0==e{exit} f' "$AG"; }
count_line() { grep -cxF -- "$1" "$AG" 2>/dev/null || true; }

# ---------- 상태 판단 ----------
CONFLICTS=0; PLAN=()
nb=$( [ -f "$AG" ] && count_line "$BEGIN" || echo 0 )
ne=$( [ -f "$AG" ] && count_line "$END" || echo 0 )
if [ "$nb" = 0 ] && [ "$ne" = 0 ]; then
  BLOCK=absent
elif [ "$nb" = 1 ] && [ "$ne" = 1 ]; then
  if diff -q <(current_block) "$RULES" >/dev/null; then BLOCK=same; else BLOCK=differs; fi
else
  BLOCK=broken
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
  elif cmp -s "$src" "$dst"; then PLAN+=("유지   $(rel "$dst") (이미 같음)")
  else PLAN+=("충돌   $(rel "$dst") 내용이 다름"); CONFLICTS=$((CONFLICTS+1))
  fi
done
for pair in "${KEEP[@]}"; do
  dst="${pair#*|}"
  if [ -e "$dst" ]; then PLAN+=("보존   $(rel "$dst") (기존 파일 그대로)"); else PLAN+=("생성   $(rel "$dst")"); fi
done

kit_rev="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"

# ---------- 제거 ----------
if [ "$MODE" = remove ]; then
  if [ "$BLOCK" = same ] || [ "$BLOCK" = differs ]; then
    tmp="$(mktemp)"
    awk -v b="$BEGIN" -v e="$END" '$0==b{f=1;next} $0==e{f=0;next} !f' "$AG" > "$tmp"
    if grep -q '[^[:space:]]' "$tmp"; then cat "$tmp" > "$AG"; echo "제거   $(rel "$AG") 규칙 블록"
    else rm -f "$AG"; echo "삭제   $(rel "$AG") (블록만 있던 파일)"; fi
    rm -f "$tmp"
  elif [ "$BLOCK" = broken ]; then
    echo "건너뜀 $(rel "$AG") 표식 짝이 맞지 않아 직접 정리 필요"
  fi
  for pair in "${MANAGED[@]}"; do
    src="${pair%%|*}"; dst="${pair#*|}"
    if [ -e "$dst" ] && cmp -s "$src" "$dst"; then
      rm -f "$dst"; rmdir "$(dirname "$dst")" 2>/dev/null || true; echo "삭제   $(rel "$dst")"
    elif [ -e "$dst" ]; then echo "남김   $(rel "$dst") (수정됨)"; fi
  done
  rmdir "$TARGET/.agents/skills" "$TARGET/.agents" 2>/dev/null || true
  echo "작업 문서(docs/, AI_COLLABORATION.md, HOW_TO_USE.md, scripts/verify.sh)는 남겨 둡니다."
  exit 0
fi

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
if [ "$BLOCK" = absent ]; then
  if [ -s "$AG" ]; then
    [ -n "$(tail -c1 "$AG")" ] && printf '\n' >> "$AG"
    printf '\n' >> "$AG"
  fi
  { printf '%s\n' "$BEGIN"; cat "$RULES"; printf '%s\n' "$END"; } >> "$AG"
fi
for pair in "${MANAGED[@]}" "${KEEP[@]}"; do
  src="${pair%%|*}"; dst="${pair#*|}"
  if [ ! -e "$dst" ]; then mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; fi
done
chmod +x "$TARGET/scripts/verify.sh" 2>/dev/null || true

cat <<EOF
설치 완료 (키트 커밋 $kit_rev — AI_COLLABORATION.md '사용한 공개 자료'에 적으세요)
다음:
  1. Codex를 이 폴더에서 새로 연다 (이미 열린 세션에는 스킬이 반영되지 않음)
  2. /status 와 /skills 로 규칙·스킬 7개 확인. 안 보이면 ".agents/skills/kickoff/SKILL.md 읽고 따라"
  3. \$kickoff 시작 HH:MM, 과제 마감 HH:MM
끄기: bash $KIT_DIR/install.sh --remove
EOF
