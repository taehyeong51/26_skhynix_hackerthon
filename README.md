# cofa-kit (SK하이닉스 AI 해커톤 2차 예선 개인 키트)

Cofa-Probe 환경(웹 IDE + 제공 Codex)에서 쓰는 작은 작업 규칙·스킬·양식 모음입니다. 문제 내용이나 과제용 앱 코드는 없고, 절차와 양식만 있습니다. 비공식 개인 자료입니다.

## 설치 (과제 폴더 터미널에서)

```bash
git clone --depth 1 https://github.com/taehyeong51/26_skhynix_hackerthon /tmp/kit && bash /tmp/kit/install.sh
```

- 키트 원본은 `/tmp/kit`에 두고, 과제 폴더에는 아래만 들어갑니다.
  - `AGENTS.md` 안의 `<!-- cofa-kit:begin -->` … `<!-- cofa-kit:end -->` 블록 (`AGENTS.override.md`가 있으면 그쪽)
  - `.agents/skills/` 7개
  - `docs/TASK.md`, `docs/DECISIONS.md`, `docs/FAILURE_MODES.md`, `docs/HANDOFF.md`
  - `AI_COLLABORATION.md`, `HOW_TO_USE.md`, `scripts/verify.sh` (같은 이름이 있으면 건드리지 않음)
- 먼저 보기만: `bash /tmp/kit/install.sh --check`
- 기존 키트 파일과 내용이 다르면 아무것도 쓰지 않고 중단합니다. 네트워크·전역 설정(~/.codex)은 건드리지 않습니다.
- 설치 후 Codex를 **새로** 열고 `/status`, `/skills`로 확인합니다. 스킬이 안 보이면 `.agents/skills/kickoff/SKILL.md 읽고 따라`처럼 경로로 지정합니다.
- 과제가 요구하는 산출물 경로가 다르면 `$kickoff`가 README를 보고 옮깁니다.

## 첫 프롬프트

```
$kickoff 시작 19:05, 과제 마감 22:05
```

이후 `$interview` → `$plan` → `$slice`(반복) → 사건마다 `$collab-log` → `$verify` → `$wrapup`.

| 스킬 | 하는 일 |
| --- | --- |
| kickoff | README → docs/TASK.md 계약서, preflight, 시각표 |
| interview | 담당자 질문 복사용 문구(한 질문 한 사실), 답 요약 반영, 합의문 |
| plan | 슬라이스, 완료 조건↔테스트 매핑, 역할 매트릭스, FAILURE_MODES |
| slice | 기대값·테스트 먼저 → 구현 → 실행 → 커밋 → 기록 |
| verify | scripts/verify.sh 채워 실행, 통과·실패·미실행 표, Browser 확인 목록 |
| collab-log | 사건 하나를 AI_COLLABORATION.md에 증상→재현→판단→확인으로 |
| wrapup | HOW_TO_USE 마무리, 제출물 경계 점검, 셀프 질문 6개 |

## 끄기

```bash
bash /tmp/kit/install.sh --remove
```

규칙 블록과 수정하지 않은 스킬만 지우고 작업 문서는 남깁니다. 키트가 15분 넘게 방해되면 끄고 순정 Codex로 진행합니다.

## 구성

```
install.sh                설치·확인·제거
AGENTS.md                 병합될 작업 규칙
.agents/skills/           kickoff interview plan slice verify collab-log wrapup
templates/                TASK DECISIONS FAILURE_MODES AI_COLLABORATION HOW_TO_USE HANDOFF
scripts/preflight.sh      환경 점검 (읽기 전용): bash /tmp/kit/scripts/preflight.sh
scripts/verify_template.sh 검증 진입점 틀 (검사 0건이면 exit 2)
docs/RUNBOOK.md           19:00~23:00 운영표 (과제 폴더로 복사하지 않음)
docs/QA_PREP.md           서술형 대비 (과제 폴더로 복사하지 않음)
tests/test_install.sh     설치기 오프라인 테스트
```

## 운영 규칙
- 2차 결과 통지 전까지 Public 유지.
- 시험 당일 16:00 이후 수정하지 않습니다. 사용한 커밋 해시를 `AI_COLLABORATION.md` '사용한 공개 자료'에 적습니다.
- 참고한 공개 키트는 [NOTICE](NOTICE)에 있습니다. 코드는 복사하지 않고 아이디어만 다시 썼습니다.
