#!/usr/bin/env python3
"""브라우저 E2E 확인 (Playwright, Python). install.sh가 과제 폴더의 scripts/e2e.py로 복사한다.

사용
  python3 scripts/e2e.py           시나리오 실행
  python3 scripts/e2e.py --check   Playwright와 브라우저를 쓸 수 있는지만 확인

환경 변수
  BASE_URL      기본 http://127.0.0.1:3000
  E2E_HEADED=1  창을 띄워 실행
  E2E_SHOTS     실패 스크린샷 폴더 (기본 /tmp/e2e-shots, 과제 폴더 밖)
  E2E_CHROMIUM  브라우저 실행 파일 경로 (자동으로 못 찾을 때)

종료 코드
  0 전부 통과 / 1 실패 있음 / 2 실행된 단계 0건 / 3 Playwright 또는 브라우저 없음(미실행)

패키지나 브라우저를 설치하지 않는다. 3이 나오면 사람이 Browser에서 같은 목록을 확인하고 기록한다.
Python 3.9 호환.
"""
import glob
import os
import sys
import traceback
from contextlib import contextmanager

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:3000").rstrip("/")
HEADED = os.environ.get("E2E_HEADED") == "1"
SHOTS = os.environ.get("E2E_SHOTS", "/tmp/e2e-shots")
TIMEOUT_MS = 5000

RESULTS = []          # (상태, 이름, 메모)
CONSOLE_ERRORS = []   # 모든 페이지의 console error / page error


# ---------------------------------------------------------------- 도우미
@contextmanager
def step(page, name):
    """with step(page, "E1 로그인"): ... 블록 안에서 예외가 나면 FAIL로 기록하고 다음 단계로 간다."""
    try:
        yield
        RESULTS.append(("PASS", name, ""))
    except Exception as e:  # noqa: BLE001 - 단계 실패를 기록하고 계속
        note = (str(e).strip().splitlines() or [type(e).__name__])[0][:200]
        shot = ""
        try:
            os.makedirs(SHOTS, exist_ok=True)
            shot = os.path.join(SHOTS, "fail-%02d.png" % (len(RESULTS) + 1))
            page.screenshot(path=shot, full_page=True)
        except Exception:
            shot = ""
        RESULTS.append(("FAIL", name, note + (" [shot %s]" % shot if shot else "")))


def open_page(browser):
    """역할마다 새 컨텍스트(쿠키 분리)로 페이지를 연다."""
    page = browser.new_context().new_page()
    page.set_default_timeout(TIMEOUT_MS)
    def on_console(m):
        url = (m.location or {}).get("url", "") if isinstance(m.location, dict) else ""
        if m.type == "error" and "favicon" not in url:   # favicon 404는 무시
            CONSOLE_ERRORS.append("console: " + m.text[:200] + (" (%s)" % url if url else ""))
    page.on("console", on_console)
    page.on("pageerror", lambda e: CONSOLE_ERRORS.append("pageerror: " + str(e)[:200]))
    return page


def see(page, text):
    """화면에 text가 보일 때까지 기다린다. 없으면 실패."""
    page.get_by_text(text).first.wait_for(state="visible", timeout=TIMEOUT_MS)


def not_see(page, text):
    """화면에 text가 없어야 한다."""
    n = page.get_by_text(text).count()
    assert n == 0, "보이면 안 되는 '%s'가 %d개" % (text, n)


def goto(page, path="/", max_status=399):
    resp = page.goto(BASE_URL + path, wait_until="domcontentloaded")
    status = resp.status if resp else None
    assert status is not None and status <= max_status, "%s -> status %s" % (path, status)
    return status


# ---------------------------------------------------------------- 시나리오
def scenario(browser):
    """과제에 맞게 단계를 추가한다. 이름 앞에 E번호, 대응하는 완료 조건 R번호를 붙인다."""
    page = open_page(browser)

    with step(page, "E0 첫 화면 열림 (HTTP < 400)"):
        goto(page, "/")

    with step(page, "E0 콘솔 에러 없음"):
        assert page.url.startswith(BASE_URL), "첫 화면이 열리지 않아 확인 불가"
        page.wait_for_load_state("networkidle")
        assert not CONSOLE_ERRORS, "; ".join(CONSOLE_ERRORS[:3])

    # ---- 아래는 예시. 과제의 선택자와 문구로 바꿔서 주석을 푼다 ----
    # with step(page, "E1 (R1) 운영자 로그인"):
    #     goto(page, "/login")
    #     page.fill("input[name=username]", "admin")
    #     page.fill("input[name=password]", "admin1234")
    #     page.click("button[type=submit]")
    #     see(page, "로그아웃")
    #
    # with step(page, "E2 (R1) 잘못된 비밀번호는 거부"):
    #     p2 = open_page(browser)
    #     goto(p2, "/login")
    #     p2.fill("input[name=username]", "admin")
    #     p2.fill("input[name=password]", "wrong")
    #     p2.click("button[type=submit]")
    #     see(p2, "비밀번호")
    #
    # with step(page, "E3 새로고침 후 로그인·데이터 유지"):
    #     page.reload()
    #     see(page, "로그아웃")
    #
    # with step(page, "E4 (R3) 일반 사용자는 운영자 주소 직접 접근 불가"):
    #     user = open_page(browser)
    #     ...일반 사용자로 로그인...
    #     status = user.goto(BASE_URL + "/admin").status
    #     assert status in (401, 403) or "/login" in user.url, "status %s url %s" % (status, user.url)
    #
    # with step(page, "E5 (R2) 빈 값·잘못된 형식 입력 → 오류 메시지, 저장 안 됨"):
    #     ...
    #
    # with step(page, "E6 (R4) 핵심 버튼 연타 → 결과 1건, 기존 결과 보존"):
    #     page.click("#generate"); page.click("#generate")
    #     page.wait_for_load_state("networkidle")
    #     assert page.locator(".result-row").count() == 1


# ---------------------------------------------------------------- 실행
def browser_candidates():
    paths = [os.environ.get("E2E_CHROMIUM")]
    roots = [os.environ.get("PLAYWRIGHT_BROWSERS_PATH"), os.path.expanduser("~/.cache/ms-playwright"), "/opt/pw-browsers"]
    for root in filter(None, roots):
        paths += sorted(glob.glob(os.path.join(root, "chromium-*", "chrome-linux*", "chrome")), reverse=True)
        paths.append(os.path.join(root, "chromium"))
    paths += ["/usr/bin/chromium", "/usr/bin/chromium-browser", "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable"]
    seen = []
    for p in paths:
        if p and os.path.exists(p) and p not in seen:
            seen.append(p)
    return seen


def launch(p):
    errors = []
    try:
        return p.chromium.launch(headless=not HEADED), "playwright 기본 chromium"
    except Exception as e:
        errors.append(str(e).splitlines()[0])
    for path in browser_candidates():
        try:
            return p.chromium.launch(headless=not HEADED, executable_path=path), path
        except Exception as e:
            errors.append("%s: %s" % (path, str(e).splitlines()[0]))
    for channel in ("chrome", "msedge"):
        try:
            return p.chromium.launch(headless=not HEADED, channel=channel), "channel " + channel
        except Exception as e:
            errors.append("channel %s: %s" % (channel, str(e).splitlines()[0]))
    raise RuntimeError(" | ".join(errors))


def main(argv):
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("미실행: Python playwright 패키지가 없습니다. 설치하지 말고 Browser에서 사람이 확인하세요.")
        return 3
    with sync_playwright() as p:
        try:
            browser, how = launch(p)
        except Exception as e:
            print("미실행: 브라우저를 실행하지 못했습니다:", str(e)[:400])
            return 3
        print("브라우저:", how)
        if "--check" in argv:
            browser.close()
            print("사용 가능")
            return 0
        print("대상:", BASE_URL)
        try:
            scenario(browser)
        except Exception:
            RESULTS.append(("FAIL", "시나리오 중단 (step 밖 예외)", traceback.format_exc().splitlines()[-1][:200]))
        browser.close()

    for status, name, note in RESULTS:
        print("  %s | %s%s" % (status, name, (" — " + note) if note else ""))
    passed = sum(1 for r in RESULTS if r[0] == "PASS")
    failed = len(RESULTS) - passed
    print("E2E RESULT: PASS %d / FAIL %d" % (passed, failed))
    if not RESULTS:
        print("실행된 단계 0건: 실패로 처리")
        return 2
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
