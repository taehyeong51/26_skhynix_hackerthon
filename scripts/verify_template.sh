#!/usr/bin/env bash
# 과제 검증 진입점. install.sh가 과제 폴더의 scripts/verify.sh로 복사한다.
# 아래 '검사 목록'만 과제에 맞게 채운다. 네트워크는 localhost만 쓴다.
# exit 0 = 전부 통과 / 1 = 실패 있음 / 2 = 실행된 검사 0건 (실패로 취급)
set -u
cd "$(dirname "$0")/.." || exit 1
PORT="${PORT:-3000}"
PASS=0; FAIL=0; SKIP=0; ROWS=()

check() {   # check "R1 설명" 명령 [인자...]
  local name="$1"; shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then PASS=$((PASS+1)); ROWS+=("PASS | $name")
  else FAIL=$((FAIL+1)); ROWS+=("FAIL | $name (exit $rc)"); printf '%s\n' "$out" | tail -5 | sed 's/^/    /'
  fi
}
skip() { SKIP=$((SKIP+1)); ROWS+=("SKIP | $1 — ${2:-이유 미기재}"); }

# 테스트 명령을 실행하고, 테스트가 0건 돌았으면 실패로 본다.
tests_ran() {
  local out rc; out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out" | tail -3
  [ $rc -eq 0 ] || return $rc
  if printf '%s\n' "$out" | grep -Eqi 'Ran 0 tests|no tests ran|collected 0 items|^# tests 0|0 passing|No tests found'; then
    echo "테스트 0건 실행"; return 3
  fi
}

# HTTP 상태 코드 확인 (python3 표준 라이브러리, localhost 전용)
http_status() {   # http_status URL 기대코드
  python3 - "$1" "$2" <<'EOF'
import sys, urllib.request, urllib.error, urllib.parse
url, want = sys.argv[1], int(sys.argv[2])
if urllib.parse.urlparse(url).hostname not in ("127.0.0.1", "localhost", "0.0.0.0"):
    print("localhost만 허용:", url); sys.exit(4)
try:
    code = urllib.request.urlopen(url, timeout=5).status
except urllib.error.HTTPError as e:
    code = e.code
except Exception as e:
    print("접속 실패:", e); sys.exit(1)
print("status", code)
sys.exit(0 if code == want else 1)
EOF
}

# 포트가 0.0.0.0 또는 :: 에 바인딩됐는지 /proc/net/tcp로 확인 (Linux)
bound_all() {   # bound_all 포트
  python3 - "$1" <<'EOF'
import sys
port = int(sys.argv[1]); seen = []
for f, anyaddr in (("/proc/net/tcp", "00000000"), ("/proc/net/tcp6", "0" * 32)):
    try:
        rows = open(f).read().splitlines()[1:]
    except OSError:
        continue
    for r in rows:
        p = r.split()
        addr, hexport = p[1].split(":")
        if p[3] == "0A" and int(hexport, 16) == port:
            seen.append(addr)
            if addr == anyaddr:
                print("LISTEN all-interfaces on", port); sys.exit(0)
print("LISTEN", port, "주소:", seen or "없음", "-> 0.0.0.0 바인딩 필요" if seen else "-> 서버 미실행")
sys.exit(1)
EOF
}

# ===== 검사 목록 (과제 완료 조건 R번호에 맞게 채운다) =====
# check "R1 단위 테스트"        tests_ran python3 -m pytest -q
# check "R1 단위 테스트"        tests_ran python3 -m unittest discover -s tests
# check "R2 첫 화면 200"        http_status "http://127.0.0.1:$PORT/" 200
# check "R2 0.0.0.0 바인딩"     bound_all "$PORT"
# check "R3 권한 없는 접근 403" http_status "http://127.0.0.1:$PORT/admin" 403
# skip  "R4 화면 새로고침 유지" "Browser에서 사람이 확인"
# =========================================================

echo "== 결과"
for r in "${ROWS[@]+"${ROWS[@]}"}"; do echo "  $r"; done
echo "RESULT: PASS $PASS / FAIL $FAIL / SKIP $SKIP"
if [ $((PASS+FAIL)) -eq 0 ]; then echo "실행된 검사 0건: 실패로 처리"; exit 2; fi
[ $FAIL -eq 0 ] || exit 1
exit 0
