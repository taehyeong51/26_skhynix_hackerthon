#!/usr/bin/env bash
# stageshow(benjitaylor/skills) 를 고정 커밋으로 /tmp/kit-extras/stageshow 에 받는다. 과제 폴더에는 아무것도 쓰지 않는다.
# 공개 GitHub clone만 쓴다(10/31 안내 기준 허용). npm install은 하지 않는다.
# 사용: bash /tmp/kit/scripts/fetch_stageshow.sh [대상 폴더]
set -euo pipefail
REPO=https://github.com/benjitaylor/skills
SHA=802057409787133703c56001080169e347305572
DEST="${1:-/tmp/kit-extras/stageshow}"
SRC="$DEST.repo"

if [ -f "$DEST/SKILL.md" ]; then echo "이미 있음: $DEST"; exit 0; fi
mkdir -p "$SRC"
git -C "$SRC" init -q
git -C "$SRC" remote add origin "$REPO" 2>/dev/null || true
git -C "$SRC" fetch -q --depth 1 origin "$SHA"
git -C "$SRC" -c advice.detachedHead=false checkout -q FETCH_HEAD
got="$(git -C "$SRC" rev-parse HEAD)"
[ "$got" = "$SHA" ] || { echo "커밋 불일치: $got" >&2; exit 1; }
ln -sfn "$SRC/stageshow" "$DEST"
echo "stageshow 준비: $DEST (커밋 ${SHA:0:7})"
echo "React 키트 실행에는 npm 의존성이 필요합니다. 시험장에서는 설치하지 말고 SKILL.md와 references/만 읽어 쓰세요."
