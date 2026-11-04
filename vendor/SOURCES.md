# vendor — 외부 스킬 출처

GitHub에서 별이 많은 스킬 레포를 조사해, 이 키트(시험장 Codex, 오프라인, 웹 서비스 과제)에 맞는 것만 원문 그대로 복사했습니다. 각 폴더에는 원 저작자의 LICENSE가 들어 있습니다. 원문은 수정하지 않았습니다. 수정이 필요한 부분은 키트 AGENTS 블록이 우선한다는 규칙으로 처리합니다.

조사일 2026-11-04. 별 수는 GitHub 검색 API 기준입니다.

## 포함한 스킬

| 스킬 | 레포 (별) | 커밋 | 라이선스 | 묶음 | 이 키트에서 쓰는 곳 |
| --- | --- | --- | --- | --- | --- |
| verification-before-completion | [obra/superpowers](https://github.com/obra/superpowers) (311,886) | `22f0b46` | MIT | core | 완료 선언 전 실행 증거. AGENTS 4번과 같은 원칙 |
| systematic-debugging | obra/superpowers | `22f0b46` | MIT | core | 같은 실패 2번이면 원인 추적 절차 |
| test-driven-development | obra/superpowers | `22f0b46` | MIT | core | $slice의 '테스트 먼저' 상세 |
| ponytail | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (183,765) | `96608e0` | MIT | core | 과설계 방지, 가장 작은 완결 변경 |
| incremental-implementation | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (113,058) | `301b02b` | MIT | core | 얇고 검증 가능한 슬라이스 |
| security-and-hardening | addyosmani/agent-skills | `301b02b` | MIT | web | 로그인·권한·입력 검증 (10/31 로그인 문제) |
| webapp-testing | [anthropics/skills](https://github.com/anthropics/skills) (187,128) | `ca45fc4` | Apache-2.0 (폴더 안 LICENSE.txt) | web | Python Playwright로 로컬 웹앱 확인, `with_server.py` |
| frontend-design | anthropics/skills | `ca45fc4` | Apache-2.0 (폴더 안 LICENSE.txt) | web | 화면 디자인 방향, 템플릿 같은 기본값 피하기 |
| frontend-ui-engineering | addyosmani/agent-skills | `301b02b` | MIT | web | 화면 상태(빈·오류·로딩), 접근성, 반응형. 예시 코드는 React·Tailwind지만 원칙은 프레임워크와 무관하며 설치를 요구하지 않음. 키트 `$ux`의 구현·점검 보조 |
| fixing-accessibility | [ibelick/ui-skills](https://github.com/ibelick/ui-skills) (10,581) | `73fb128` | MIT | web | 폼·버튼·키보드·대비 점검 (프레임워크 무관) |

설치: `bash /tmp/kit/install.sh --extras core,web` (묶음 대신 스킬 이름을 쉼표로 줘도 됨).

## 선택 설치 (네트워크 clone)

| 스킬 | 레포 (별) | 커밋 | 라이선스 | 비고 |
| --- | --- | --- | --- | --- |
| stageshow | [benjitaylor/skills](https://github.com/benjitaylor/skills) (1,470) | `8020574` | MIT, 단 `assets/app-icons.ts` 등 앱 아이콘 그림은 제외 (원 NOTICE.md) | 마케팅용 가짜 제품 화면·데모 애니메이션. React·npm 필요. 3.4MB이고 MIT가 아닌 그림이 섞여 있어 복사하지 않고 `--extras stageshow`일 때 /tmp로 핀 고정 clone |

## 검토했지만 제외

| 레포 (별) | 스킬 | 제외 이유 |
| --- | --- | --- |
| [mattpocock/skills](https://github.com/mattpocock/skills) (311,514) | tdd, diagnosing-bugs, handoff, grill-me | tdd는 시험 단위(seam)를 사용자와 먼저 합의하라고 해서 시간이 듦. diagnosing-bugs는 systematic-debugging과 겹침. handoff는 인계 문서를 작업 폴더 밖 /tmp에 써서 제출물 증거가 남지 않음 (키트 HANDOFF.md로 대체). grill-me는 사용자 인터뷰용이고 담당자 인터뷰는 $interview가 맡음 |
| obra/superpowers | brainstorming, writing-plans, subagent-driven-development 등 | 대화형 설계 절차가 길어서 4시간 과제와 키트 단계(kickoff~plan)와 겹침 |
| addyosmani/agent-skills | git-workflow-and-versioning | push·릴리스 태그·PR 흐름 포함. 시험은 push 금지라 docs/GIT_RULES.md로 다시 씀 |
| addyosmani/agent-skills | browser-testing-with-devtools | Chrome DevTools MCP가 필요 |
| [openai/skills](https://github.com/openai/skills) (28,501) | playwright, playwright-interactive | `npx`로 `@playwright/cli`를 내려받거나 `js_repl`이 필요. 시험장 네트워크 차단 시 동작 안 함 |
| [microsoft/playwright-cli](https://github.com/microsoft/playwright-cli) (14,928) | playwright-cli | `npm install -g` 필요 |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (101,852) | impeccable | 첫 실행 때 `curl`로 엔진 바이너리를 내려받음(시험장 네트워크 규정과 충돌), 2.3MB. 업무 화면(Operate) 원칙만 키트 `$ux`에 아이디어로 반영 |
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) (109,691) | design-taste-frontend | 랜딩·마케팅 페이지 아트 디렉션 중심, node 스크립트로 방향을 뽑고 브라우저 검사. 업무용 웹 서비스와 맞지 않음 |
| ibelick/ui-skills | baseline-ui, improve-ui | baseline-ui는 Tailwind·motion·Radix 사용을 강제(npm 필요). improve-ui는 읽기 전용 감사·계획용이라 시간 대비 효과가 작음 |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) (296,582), [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) (166,335) | 전체 | 수십~수백 개 묶음. 일괄 설치는 시험 중 읽는 비용과 충돌 위험이 큼 |

## 갱신 방법

1. 원 레포를 받아 해당 폴더를 통째로 바꾼다(수정하지 않는다).
2. 이 표의 커밋·별 수를 고친다.
3. `bash tests/test_install.sh`를 통과시키고 한 커밋으로 남긴다: `vendor: update <스킬> to <커밋>`.
