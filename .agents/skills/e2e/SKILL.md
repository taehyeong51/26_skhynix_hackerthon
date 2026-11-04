---
name: e2e
description: Playwright(Python)로 브라우저 확인을 자동화한다. 첫 E2E 슬라이스 직후와 $verify 때 scripts/e2e.py에 로그인·권한·새로고침·잘못된 입력·연타 시나리오를 채워 실행한다. Playwright나 브라우저가 없으면 설치하지 않고 사람 확인 목록으로 돌린다.
---

# e2e

1. 사용 가능 확인: `python3 scripts/e2e.py --check`
   - exit 0: 진행.
   - exit 3(미실행): pip install·playwright install을 하지 않는다. 아래 시나리오 목록을 사람이 Browser에서 확인할 체크리스트로 바꿔 사용자에게 주고, 결과를 AI_COLLABORATION.md에 '사람 확인'으로 기록한다. 여기서 끝.
   - Node playwright만 있으면(`node -e "require('playwright')"` 성공) 같은 시나리오를 `scripts/e2e.mjs`로 짧게 옮겨도 된다. 새 패키지는 쓰지 않는다.
2. 시나리오 작성: scripts/e2e.py의 `scenario()`에 단계를 추가한다. 단계마다 `with step(page, "E번호 (R번호) 설명"):`.
   - 선택자는 실제 화면에서 확인한다. 먼저 `page.content()`나 스크린샷을 보고, 추측으로 쓰지 않는다.
   - 역할마다 `open_page(browser)`로 새 컨텍스트를 연다(쿠키 분리).
   - 기본 목록: 로그인 성공 / 잘못된 비밀번호 거부 / 새로고침 후 상태 유지 / 다른 역할이 주소를 직접 쳐서 접근하면 차단 / 빈 값·잘못된 형식 입력 시 오류와 저장 안 됨 / 핵심 버튼 연타·처리 중 재요청 시 결과 1건과 기존 결과 보존. docs/SCREENS.md가 있으면 화면별 상태(비어 있음, 오류, 권한 없음) 문구도 단계로 넣는다.
   - 기대값은 화면 문구나 개수처럼 구체적으로. `see`, `not_see`, `goto`, `count()`를 쓴다.
3. 실행: 서버를 0.0.0.0으로 띄운 상태에서 `BASE_URL=http://127.0.0.1:<포트> python3 scripts/e2e.py`. 출력의 PASS/FAIL 줄을 그대로 보여 준다. 실패 스크린샷은 /tmp/e2e-shots에 남는다(과제 폴더 밖).
4. 실패하면 화면 문제인지 시나리오 문제(선택자·대기)인지 먼저 가른다. 시나리오 문제로 통과시키려고 기대값을 낮추지 않는다.
5. scripts/verify.sh에 `check_e2e "R5 브라우저 시나리오"` 한 줄을 넣는다. Playwright가 없으면 자동으로 SKIP으로 기록된다.
6. 실제로 버그를 잡았으면 $collab-log로 한 건 기록한다(발견: e2e 단계 이름).

더 복잡한 화면 조작(서버 여러 개 동시 실행, DOM 탐색)이 필요하면 vendor 스킬 `webapp-testing`(설치했다면)을 참고한다.
