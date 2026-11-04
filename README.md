# cofa-kit (SK하이닉스 AI 해커톤 2차 예선 개인 키트)

Cofa-Probe 환경(웹 IDE + 제공 Codex)에서 쓰는 작업 규칙·스킬·양식 모음입니다. 문제 내용이나 과제용 앱 코드는 없고, 절차와 양식만 있습니다. 비공식 개인 자료입니다.

- 키트 스킬 8개: 단계별 진행 (kickoff → interview → plan → slice → e2e → verify → wrapup, 사건마다 collab-log)
- 외부 스킬 9개 (선택): GitHub 별이 많은 스킬 레포에서 골라 원문 그대로 넣은 것 ([vendor/SOURCES.md](vendor/SOURCES.md))
- Playwright E2E: `scripts/e2e.py` 템플릿. 없으면 설치하지 않고 사람 확인으로 돌림
- stageshow (선택): UI 데모·시각 다듬기 스킬, 고정 커밋 clone
- [단계별 프롬프트](docs/PROMPTS.md), [형상관리 규칙](docs/GIT_RULES.md), [운영표](docs/RUNBOOK.md), [서술형 대비](docs/QA_PREP.md)

## 설치 (과제 폴더 터미널에서)

먼저 과제 초기 상태를 커밋해 기준점을 만듭니다([GIT_RULES A1](docs/GIT_RULES.md)).

```bash
git clone --depth 1 https://github.com/taehyeong51/26_skhynix_hackerthon /tmp/kit && bash /tmp/kit/install.sh --extras core,web
```

| 옵션 | 내용 |
| --- | --- |
| (없음) | 규칙 블록 + 키트 스킬 8개 + 양식 |
| `--extras core` | + verification-before-completion, systematic-debugging, test-driven-development (obra/superpowers), ponytail, incremental-implementation (addyosmani/agent-skills) |
| `--extras web` | + webapp-testing, frontend-design (anthropics/skills), fixing-accessibility (ibelick/ui-skills), security-and-hardening (addyosmani/agent-skills) |
| `--extras stageshow` | + stageshow 연결 스킬. 원본은 /tmp/kit-extras로 clone (이 옵션만 네트워크 사용) |
| `--extras <스킬 이름>` | vendor 스킬 하나만 (쉼표로 여러 개) |
| `--check` | 쓰지 않고 할 일만 출력 |
| `--remove` | 규칙 블록과 수정 안 된 스킬 제거. 작업 문서는 남김 |

과제 폴더에 들어가는 것:
- `AGENTS.md` 안의 `<!-- cofa-kit:begin -->` … `<!-- cofa-kit:end -->` 블록 (`AGENTS.override.md`가 있으면 그쪽)
- `.agents/skills/` (8개 + 선택한 외부 스킬)
- `docs/TASK.md`, `docs/DECISIONS.md`, `docs/FAILURE_MODES.md`, `docs/HANDOFF.md`
- `AI_COLLABORATION.md`, `HOW_TO_USE.md`, `scripts/verify.sh`, `scripts/e2e.py`, `.gitignore` (같은 이름이 있으면 건드리지 않음)

설치기는 패키지 설치, 전역 설정(~/.codex) 수정, 기존 파일 덮어쓰기, git 커밋을 하지 않습니다. 기존 키트 파일과 내용이 다르면 아무것도 쓰지 않고 중단합니다.

설치 후 Codex를 **새로** 열고 `/status`, `/skills`로 확인합니다. 스킬이 안 보이면 `.agents/skills/kickoff/SKILL.md 읽고 따라`처럼 경로를 지정합니다.

## 쓰는 순서

```
$kickoff 시작 19:05, 과제 마감 22:05
```

단계마다 붙여 넣을 문장은 [docs/PROMPTS.md](docs/PROMPTS.md)에 있습니다. 시험 중에는 `cat /tmp/kit/docs/PROMPTS.md`로 엽니다.

| 단계 | 스킬 | 하는 일 | 함께 쓰는 외부 스킬 |
| --- | --- | --- | --- |
| 계약 | kickoff | README → docs/TASK.md, preflight, 시각표, git 기준점 확인 | |
| 인터뷰 | interview | 담당자 질문 복사용 문구(한 질문 한 사실), 답 반영, 합의문 | |
| 계획 | plan | 슬라이스, 완료 조건↔테스트, 역할 매트릭스, FAILURE_MODES | ponytail |
| 구현 | slice | 기대값·테스트 먼저 → 구현 → 실행 → 커밋 → 기록 | test-driven-development, incremental-implementation |
| 화면 확인 | e2e | Playwright 시나리오(로그인·권한·새로고침·입력·연타) | webapp-testing |
| 막힘 | collab-log | 사건을 증상→재현→판단→확인으로 기록 | systematic-debugging |
| 검증 | verify | verify.sh 실행, 통과·실패·미실행 표, 사람 확인 목록 | verification-before-completion, security-and-hardening |
| 마무리 | wrapup | 산출물 정리, 제출물 경계, 태그, 셀프 질문 6개 | fixing-accessibility, frontend-design |

외부 스킬은 보조입니다. 키트 AGENTS 블록과 충돌하면 블록이 우선합니다(push·PR·브랜치·패키지 설치 지시는 따르지 않음).

## Playwright

```bash
python3 scripts/e2e.py --check                      # 쓸 수 있는지 (0 가능 / 3 미실행)
BASE_URL=http://127.0.0.1:3000 python3 scripts/e2e.py
```

- 시나리오는 `scenario()`에 `with step(page, "E1 (R1) ..."):` 블록으로 추가합니다. 예시 6개(로그인, 잘못된 비밀번호, 새로고침, 역할 차단, 잘못된 입력, 연타)가 주석으로 들어 있습니다.
- 브라우저는 Playwright 기본값 → 알려진 경로(`~/.cache/ms-playwright`, `/opt/pw-browsers`, `/usr/bin/chromium` 등) → 시스템 Chrome 순서로 찾습니다.
- favicon 404는 콘솔 에러에서 제외합니다. 실패 스크린샷은 `/tmp/e2e-shots`(과제 폴더 밖)에 남습니다.
- verify.sh에서는 `check_e2e "R4 ..."` 한 줄로 연결하고, 없으면 SKIP으로 기록됩니다.

## 끄기

```bash
bash /tmp/kit/install.sh --remove
```

키트가 15분 넘게 방해되면 끄고 순정 Codex로 진행합니다.

## 구성

```
install.sh                  설치·확인·제거 (--extras)
AGENTS.md                   병합될 작업 규칙 (형상관리·외부 스킬 우선순위 포함)
.agents/skills/             키트 스킬 8개
vendor/skills/              외부 스킬 9개 (원문 + LICENSE), vendor/SOURCES.md
extras/stageshow/SKILL.md   stageshow 연결 스킬
templates/                  TASK DECISIONS FAILURE_MODES AI_COLLABORATION HOW_TO_USE HANDOFF gitignore
scripts/preflight.sh        환경 점검 (읽기 전용, Playwright 감지 포함)
scripts/verify_template.sh  검증 진입점 틀 (검사 0건이면 exit 2, check_e2e)
scripts/e2e_template.py     Playwright E2E 틀 (Python 3.9 호환)
scripts/fetch_stageshow.sh  stageshow 고정 커밋 clone
docs/                       PROMPTS, GIT_RULES, RUNBOOK, QA_PREP (과제 폴더로 복사하지 않음)
tests/test_install.sh       설치기·스크립트 오프라인 테스트
```

## 운영 규칙
- 2차 결과 통지 전까지 Public 유지.
- 시험 당일 16:00 이후 수정하지 않습니다. `exam-YYYYMMDD` 태그를 붙이고, 그 커밋 해시를 `AI_COLLABORATION.md` '사용한 공개 자료'에 적습니다.
- 키트 자체 관리 규칙은 [GIT_RULES B](docs/GIT_RULES.md)를 따릅니다.
- 참고 자료와 외부 스킬 라이선스는 [NOTICE](NOTICE)와 [vendor/SOURCES.md](vendor/SOURCES.md)에 있습니다.
