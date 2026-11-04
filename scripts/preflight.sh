#!/usr/bin/env bash
# 환경 점검 (읽기 전용). 파일을 쓰거나 네트워크에 접속하지 않는다.
# 사용: bash /tmp/kit/scripts/preflight.sh [포트 ...]   (기본 포트: 3000 5000 8000 8080)
set -u
PORTS=("$@"); [ ${#PORTS[@]} -eq 0 ] && PORTS=(3000 5000 8000 8080)

line() { printf '%-22s %s\n' "$1" "$2"; }
ver() { command -v "$1" >/dev/null 2>&1 && "$@" 2>&1 | head -1 || echo "-"; }

echo "== 버전"
line python3 "$(ver python3 --version)"
line node    "$(ver node --version)"
line npm     "$(ver npm --version)"
line git     "$(ver git --version)"
line sqlite3 "$(ver sqlite3 --version)"

PY=python3; command -v python3 >/dev/null 2>&1 || PY=""
if [ -n "$PY" ]; then
  echo "== Python 함정"
  $PY - <<'EOF'
import sys
from datetime import datetime
try:
    datetime.fromisoformat("2026-11-04T10:00:00Z"); z = "OK"
except ValueError:
    z = "실패 -> 'Z'를 '+00:00'으로 바꿔 파싱"
print(f"{'fromisoformat Z':<22} {z}")
print(f"{'sqlite3 모듈':<22} ", end="")
try:
    import sqlite3; print("OK", sqlite3.sqlite_version)
except Exception as e:
    print("-", e)
EOF
  echo "== 설치된 Python 패키지 (설치 없이 쓸 수 있는 것)"
  $PY - <<'EOF'
import importlib.util as u
mods = ["flask", "fastapi", "uvicorn", "starlette", "django", "jinja2", "sqlalchemy",
        "pydantic", "pytest", "requests", "httpx", "pandas", "numpy", "scipy",
        "ortools", "pulp", "networkx", "openai", "playwright"]
ok = [m for m in mods if u.find_spec(m)]
print(f"{'있음':<22} {' '.join(ok) or '-'}")
print(f"{'없음':<22} {' '.join(m for m in mods if m not in ok) or '-'}")
EOF
fi

if command -v npm >/dev/null 2>&1; then
  echo "== 전역 npm 패키지"
  npm ls -g --depth=0 --offline 2>/dev/null | tail -n +2 | sed 's/^/  /' | head -20
fi

echo "== Playwright (설치하지 않고 있는지만 확인)"
if [ -n "$PY" ]; then
  line "python playwright" "$($PY -c 'from importlib.metadata import version; print(version("playwright"))' 2>/dev/null || echo '-')"
fi
if command -v node >/dev/null 2>&1; then
  line "node playwright" "$(node -e 'try{console.log(require(require.resolve("playwright/package.json")).version)}catch(e){console.log("-")}' 2>/dev/null)"
fi
found=""
for d in "${PLAYWRIGHT_BROWSERS_PATH:-}" "$HOME/.cache/ms-playwright" /opt/pw-browsers; do
  [ -n "$d" ] && [ -d "$d" ] && found="$found $(ls -d "$d"/chromium* 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ')"
done
for b in chromium chromium-browser google-chrome; do command -v "$b" >/dev/null 2>&1 && found="$found $b"; done
found="$(printf '%s\n' $found | sort -u | tr '\n' ' ')"
line "브라우저" "${found:- -}"
echo "  -> python playwright와 브라우저가 둘 다 있으면 scripts/e2e.py 사용, 아니면 Browser 사람 확인"

echo "== 시간대"
line "local" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
line "UTC"   "$(date -u '+%Y-%m-%d %H:%M:%S')"
line "TZ"    "${TZ:-(unset)}"

echo "== 포트 (127.0.0.1에서 열려 있으면 사용 중)"
for p in "${PORTS[@]}"; do
  if [ -n "$PY" ]; then
    st=$($PY -c "import socket,sys;s=socket.socket();s.settimeout(0.3);print('사용 중' if s.connect_ex(('127.0.0.1',int(sys.argv[1])))==0 else '비어 있음')" "$p")
  else
    st="(python3 없음, 확인 불가)"
  fi
  line "$p" "$st"
done

echo "== 작업 폴더"
line "경로" "$PWD"
line "쓰기 권한" "$([ -w "$PWD" ] && echo OK || echo '없음')"
if command -v git >/dev/null 2>&1; then
  if git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    line "git 저장소" "예 ($(git -C "$PWD" rev-parse --abbrev-ref HEAD 2>/dev/null))"
  else
    line "git 저장소" "아니오 -> 필요하면 git init"
  fi
  n=$(git config user.name || true); e=$(git config user.email || true)
  line "git user" "${n:-(없음)} <${e:-(없음)}>"
  [ -z "$n$e" ] && echo "  ! 커밋 전에 git config user.name / user.email 설정 필요 (로컬 저장소 범위로)"
fi
exit 0
