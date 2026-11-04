# 테스트 시나리오 — 가상 과제 "회의실 예약 서비스"로 키트 시연·검증하기

작성일 2026-11-04 · 대상 커밋 `6216bc7`

> **심사기준 미확인.** 이 레포에는 심사기준 문서가 없습니다(`README.md`, `docs/`, 스킬 파일에서 '심사·평가·채점'을 검색함). 아래 4장은 일반 기준 다섯 가지를 **가정**으로 사용합니다: 문제 적합성, AI 활용의 타당성, 완성도, 검증 가능성, 설명 가능성. 레포 안에서 평가와 관련된 단서는 `docs/QA_PREP.md`의 서술형 4유형(범위·검증 경로 / 실패 경로 / 가정이 깨지는 조건 / AI 협업 사실)과 `docs/GIT_RULES.md`의 "git log는 평가 기록에 남습니다"뿐입니다.

## 먼저 알아 둘 것: 이 레포는 무엇인가

이 레포는 **AI를 직접 호출하는 앱이 아닙니다.** AI 코딩 에이전트(Codex)가 과제를 푸는 방식을 정해 주는 **작업 키트**입니다.

- AI 호출 코드는 없습니다. `--exclude-dir=vendor`로 `openai`, `anthropic`, `api_key`를 검색해도 코드가 나오지 않습니다. 네트워크 요청은 `scripts/verify_template.sh`의 localhost 확인용 `urlopen` 하나뿐이고, localhost가 아니면 거부합니다(35~36행).
- 따라서 API 키나 토큰이 필요 없습니다. 쓰는 환경 변수는 이름만 적으면 `PORT`, `BASE_URL`, `E2E_HEADED`, `E2E_SHOTS`, `E2E_CHROMIUM`, `PLAYWRIGHT_BROWSERS_PATH`, `KIT_STAGESHOW_DIR`입니다.
- 이 문서에서 "AI 호출"은 **Codex가 `AGENTS.md` 규칙과 `.agents/skills/*/SKILL.md`를 읽고 행동하는 단계**를 뜻합니다.

표기 규칙:
- `과제/…`는 레포 파일이 아니라, `install.sh`가 **과제 폴더에 만드는 파일**입니다(원본 경로를 같이 적습니다).
- 명령 속의 `scripts/verify.sh`, `scripts/e2e.py`는 과제 폴더에서 실행하므로 과제 폴더의 파일입니다(원본 `scripts/verify_template.sh`, `scripts/e2e_template.py`).
- **[실행함]**은 이 문서를 쓰면서 실제로 돌린 결과입니다. 레포 밖 임시 폴더에서 돌렸고, 외부 API 호출은 없었습니다.
- **[uncertain]**은 확인하지 못한 내용입니다. 주로 Codex의 실제 행동과 시험 플랫폼 동작입니다.

---

## 1. 가상 문제 설계

### 1-1. 주 시나리오: 사내 회의실 예약 서비스

시험 문제(10/31 출제 내용)와 무관한 가상 과제입니다. `docs/RUNBOOK.md`의 운영표와 `docs/prompts/`의 단계를 처음부터 끝까지 한 번 돌려 보는 데 씁니다.

| 항목 | 내용 |
| --- | --- |
| 배경 | 직원 120명 사무실, 회의실 4개. 예약은 공유 엑셀 파일과 메신저 공지로 관리함 |
| 사용자 | 직원(예약·본인 예약 취소), 총무 담당자(회의실 관리, 모든 예약 조정, 정기회의 배정) |
| 현재의 불편 | 같은 시간대 중복 예약이 주 2~3회 발생. 매주 월요일 총무 담당자가 정기회의 12건을 손으로 배치하는 데 약 40분 걸림. 누가 언제 바꿨는지 기록이 없음 |
| 핵심 동작 | ① 예약 생성·취소(중복 거부) ② 총무 담당자의 "주간 정기회의 배정안 생성 → 확인 → 적용" |
| 기대 결과 | 중복 예약 0건, 역할별 권한 분리, 배정안 생성이 실패해도 기존 예약이 보존됨, 실행·검증 방법이 문서로 남음 |

가상 입력 데이터(과제 폴더에 넣는 예시):

```csv
room_id,name,capacity,floor
R1,한라,4,3
R2,백두,8,3
R3,지리,12,4
R4,설악,20,4
```

```csv
reservation_id,room_id,user,role,start,end,title
B001,R1,kim,employee,2026-11-09T10:00:00Z,2026-11-09T11:00:00Z,디자인 리뷰
B002,R2,lee,employee,2026-11-09T10:30:00Z,2026-11-09T12:00:00Z,주간 회의
B003,R1,park,employee,2026-11-09T11:00:00Z,2026-11-09T11:30:00Z,1:1
```

```csv
meeting_id,team,attendees,duration_min,preferred_day,preferred_time
M01,플랫폼,7,60,MON,10:00
M02,디자인,4,30,MON,10:00
M03,영업,15,60,TUE,14:00
M04,전사,18,90,FRI,16:00
```

테스트 계정(가상): `admin / admin1234`(총무 담당자), `kim / kim1234`(직원).

기대 결과 예시:
- B003은 B001과 끝·시작이 맞닿으므로 **허용**됩니다. 이 경계 규칙은 담당자 인터뷰에서 확정할 항목입니다.
- M01(7명)은 R2(8명) 이상에만, M04(18명)는 R4에만 배정됩니다.
- 직원 `kim`이 배정안 적용 API를 직접 호출하면 403을 받습니다.

### 1-2. 보조 시나리오 A (경계): 맞닿는 시간과 연타

- 입력: 11/09 11:00–11:30 R1 예약 요청(B001의 끝과 맞닿음). 같은 요청을 버튼 연타로 2회 보냄.
- 기대: 첫 요청은 성공하고 두 번째는 중복으로 거부되어 예약은 1건만 생깁니다. 맞닿는 경계는 담당자 답에 따름(답이 없으면 `과제/docs/DECISIONS.md`에 가정으로 기록).
- 키트에서 다루는 곳: `templates/FAILURE_MODES.md`의 '중복·동시 요청' 행, `scripts/e2e_template.py`의 예시 단계 E6(연타 → 결과 1건).

### 1-3. 보조 시나리오 B (실패): 도구 쪽 실패 세 가지

| 실패 | 기대 동작 | 근거 |
| --- | --- | --- |
| 과제 폴더에 같은 이름의 수정된 스킬이 이미 있음 | 설치기가 **아무것도 쓰지 않고** 중단(exit 1) | `install.sh` 충돌 검사, `tests/test_install.sh` 4번 항목 [실행함] |
| 검사 목록을 안 채우고 검증 실행 | "실행된 검사 0건: 실패로 처리", exit 2 | `scripts/verify_template.sh` 마지막 줄들 [실행함] |
| 시험 환경에 Playwright가 없음 | `과제/scripts/e2e.py`가 exit 3(미실행), verify는 SKIP으로 기록하고 사람 확인으로 돌림 | `scripts/e2e_template.py` `main()`, `scripts/verify_template.sh` `check_e2e()` [실행함] |

---

## 2. 레포지토리 활용 방식

### 2-1. 데이터 흐름

```
[입력]
  과제 README + 가상 데이터(1-1) + 담당자 답변
        │
        ▼
[처리: 키트 설치]  install.sh --extras core,web
  ├─ AGENTS.md 규칙을 과제/AGENTS.md 에 표식 블록으로 병합
  ├─ .agents/skills/* (9개) + vendor/skills/* (10개) → 과제/.agents/skills/
  ├─ templates/* → 과제/docs/*, 과제/AI_COLLABORATION.md, 과제/HOW_TO_USE.md, 과제/.gitignore
  └─ scripts/verify_template.sh → 과제/scripts/verify.sh, scripts/e2e_template.py → 과제/scripts/e2e.py
  환경 점검: scripts/preflight.sh (읽기 전용)
        │
        ▼
[AI 호출: Codex 세션]
  Codex가 과제/AGENTS.md 와 과제/.agents/skills/<이름>/SKILL.md 를 읽음
  사용자가 docs/prompts/ 의 01~09 단계 프롬프트를 붙여 넣음
  $kickoff → $interview → $plan → $slice(반복) → $e2e → $verify → $wrapup
  (사건마다 $collab-log)                                 [uncertain: Codex 실제 행동]
        │
        ▼
[후처리: 검증과 기록]
  과제/scripts/verify.sh  (check / skip / tests_ran / http_status / bound_all / check_e2e)
  과제/scripts/e2e.py     (Playwright 시나리오, 없으면 exit 3)
  사람의 Browser 확인 → 결과를 Codex에 전달
  git commit / git tag (m1-e2e, freeze, submit)   규칙: docs/GIT_RULES.md
        │
        ▼
[출력]
  서비스 소스, 과제/AI_COLLABORATION.md, 과제/HOW_TO_USE.md,
  과제/docs/{TASK,DECISIONS,FAILURE_MODES,HANDOFF}.md, git log
```

### 2-2. 단계별 파일과 명령

| 단계 | 쓰는 레포 파일 | 명령·입력 | 결과 |
| --- | --- | --- | --- |
| 0. 기준점 | `docs/GIT_RULES.md` A1 | `git init`, `git commit -m "chore: 과제 초기 상태"` | 제공 파일만 담긴 커밋 |
| 1. 설치 확인 | `install.sh` | `bash /tmp/kit/install.sh --check --extras core,web` | 할 일 목록, 충돌 0건이면 exit 0 [실행함] |
| 2. 설치 | `install.sh`, `AGENTS.md`, `.agents/skills/`, `vendor/skills/`, `templates/` | `bash /tmp/kit/install.sh --extras core,web` | 스킬 19개, `과제/docs/` 양식 5개 [실행함] |
| 3. 환경 점검 | `scripts/preflight.sh` | `bash /tmp/kit/scripts/preflight.sh` | 버전, Playwright 유무, 시간대, 포트, git user [실행함] |
| 4. 로딩 확인 | `docs/prompts/00-setup.md` | Codex에서 `/skills` 와 확인 프롬프트 | 스킬 이름 목록 [uncertain] |
| 5. 계약서 | `.agents/skills/kickoff/SKILL.md`, `templates/TASK.md`, `docs/prompts/01-kickoff.md` | `$kickoff 시작 HH:MM, …` | `과제/docs/TASK.md` [uncertain] |
| 6. 인터뷰 | `.agents/skills/interview/SKILL.md`, `docs/prompts/02-interview.md` | 질문 표 → 답변 반영 반복 → 합의문 | TASK.md '합의' [uncertain] |
| 7. 계획 | `.agents/skills/plan/SKILL.md`, `templates/FAILURE_MODES.md`, `docs/prompts/03-plan.md` | `$plan …` | 슬라이스 표, FAILURE_MODES [uncertain] |
| 8. 최소 E2E | `.agents/skills/slice/SKILL.md`, `docs/prompts/04-first-e2e.md` | `$slice 첫 슬라이스…` + 사람 Browser 확인 | 첫 커밋, 태그 `m1-e2e` [uncertain] |
| 9. 화면 자동화 | `.agents/skills/e2e/SKILL.md`, `scripts/e2e_template.py` | `python3 scripts/e2e.py` | PASS/FAIL 줄 [실행함: 템플릿 기본 시나리오] |
| 10. 반복 | `docs/prompts/05-iterate.md`, `docs/prompts/06-stuck.md` | `$slice <R번호> …` | R번호별 커밋 [uncertain] |
| 11. 검증 | `.agents/skills/verify/SKILL.md`, `scripts/verify_template.sh` | `bash scripts/verify.sh` | `RESULT: PASS n / FAIL n / SKIP n` [실행함] |
| 12. 마무리 | `.agents/skills/wrapup/SKILL.md`, `docs/prompts/09-submit.md` | `$wrapup …` | 문서 정리, 태그 `submit` [uncertain] |
| 13. 끄기 | `install.sh` | `bash /tmp/kit/install.sh --remove` | 블록·미수정 스킬 삭제, 작업 문서 유지 [실행함] |

---

## 3. 설계 / 검증 / 로깅

### 3-1. 설계 판단이 일어나는 지점

| 지점 | 위치 | 판단 | 이유 |
| --- | --- | --- | --- |
| 규칙 우선순위 | `AGENTS.md` 첫 줄 | 플랫폼 규칙 > 과제 README·담당자 답 > 키트 | 키트가 시험 규정을 덮어쓰지 않게 |
| 외부 스킬 통제 | `AGENTS.md` '외부 스킬' 절 | vendor 스킬의 push·PR·설치 지시는 따르지 않음 | 원문을 고치지 않고(`vendor/SOURCES.md`) 충돌만 막음 |
| 설치 안전성 | `install.sh` | 표식 블록 병합, 충돌이 1건이라도 있으면 전부 중단, 기존 파일 보존 | 시험 중 과제 파일을 망가뜨리지 않게 |
| 완료 판정 | `scripts/verify_template.sh` | exit 0 통과 / 1 실패 / 2 검사 0건(실패) | "아무것도 안 돌았는데 통과"를 막음 |
| 테스트 0건 | `scripts/verify_template.sh` `tests_ran()` | "Ran 0 tests", "no tests ran" 등이 나오면 실패 | 같은 이유 |
| 도구 부재 처리 | `scripts/e2e_template.py` `main()`, `scripts/verify_template.sh` `check_e2e()` | Playwright가 없으면 설치하지 않고 exit 3 → SKIP | 시험장 네트워크 설치 금지 |
| 오탐 제거 | `scripts/e2e_template.py` `open_page()` | favicon 404는 콘솔 에러에서 제외 | 실제 문제 없는 앱이 실패로 나오지 않게 |
| 제출물 오염 방지 | `scripts/e2e_template.py` `SHOTS` | 실패 스크린샷은 `/tmp/e2e-shots` | 과제 폴더에 섞이지 않게 |
| 프롬프트 형태 | `docs/prompts/README.md` | 목표, 읽을 곳, 이번 턴 경계, 보고 형식, 멈춤 지점만 | 규칙 반복으로 에이전트를 둔하게 만들지 않음 |
| 가상 과제의 도메인 판단 | `과제/docs/DECISIONS.md` (원본 `templates/DECISIONS.md`) | 맞닿는 시간 허용 여부, 배정 알고리즘, 권한 위치 | Codex와 사용자가 정함 [uncertain] |

### 3-2. 검증 기준 (binary pass/fail)

레포의 테스트 `tests/test_install.sh`를 먼저 씁니다.

| # | 확인 | 명령 | 통과 기준 | 이번 결과 |
| --- | --- | --- | --- | --- |
| V1 | 키트 자체 테스트 | `bash tests/test_install.sh` | 마지막 줄 `PASS 70 / FAIL 0`, exit 0 | 통과 [실행함] |
| V2 | 설치 전 확인 | `bash install.sh --check --extras core,web` (과제 폴더) | `충돌 0 건`, exit 0, 폴더 변화 없음 | 통과 [실행함] |
| V3 | 설치 | `bash install.sh --extras core,web` | `.agents/skills`에 19개, `docs/`에 TASK·DECISIONS·FAILURE_MODES·HANDOFF·SCREENS | 통과(19개) [실행함] |
| V4 | 재설치가 같은 결과 | 같은 명령을 다시 실행 | exit 0, `생성` 줄 0개 | 통과 [실행함] |
| V5 | 검사 0건 거부 | `bash scripts/verify.sh` (목록 비움) | `실행된 검사 0건: 실패로 처리`, exit 2 | 통과 [실행함] |
| V6 | 서버 검사 | 검사 목록에 `http_status`, `bound_all` 추가 후 실행 | `PASS 2 / FAIL 0` | 통과 [실행함, 정적 페이지 서버] |
| V7 | Playwright 없음 | 시스템 `python3`로 `python3 scripts/e2e.py --check` | `미실행: …`, exit 3 | 통과 [실행함] |
| V8 | Playwright 있음 | Playwright가 있는 Python으로 verify 실행 | `R4 브라우저 시나리오` PASS, `PASS 3 / FAIL 0 / SKIP 0` | 통과 [실행함, 개발용 venv] |
| V9 | 끄기 | `bash install.sh --remove` | 블록·미수정 스킬 삭제, 작업 문서 유지 | 통과 [실행함] |
| V10 | 스킬 로딩 | Codex `/skills` | 키트 9개 + 외부 10개 이름 표시 | [uncertain] |
| V11 | 가상 과제 결과 | `과제/scripts/verify.sh` (과제에 맞게 채움) | R번호 전부 PASS 또는 이유 있는 SKIP | [uncertain] 시연 때 확인 |
| V12 | 기록 일치 | `git log --oneline` vs `과제/AI_COLLABORATION.md` 사건 로그 | 사건마다 해시가 log에 있음 | [uncertain] 시연 때 확인 |

V6~V8의 서버는 리허설용 정적 HTML이었습니다. 회의실 예약 앱 자체는 시연 때 Codex가 만듭니다.

### 3-3. 로깅

**로깅 프레임워크(파일 로그)는 없음.** 대신 아래 기록이 남습니다.

| 기록 | 위치 | 형식 | 시연 중 볼 곳 |
| --- | --- | --- | --- |
| 설치 결과 | 터미널 출력 | `생성 / 유지 / 보존 / 충돌` 한 줄씩 | 설치 직후 |
| 환경 점검 | 터미널 출력 | `== 버전`, `== Playwright`, `== 시간대`, `== 포트`, `== 작업 폴더` 구획 | 시작 3분 |
| 검증 결과 | 터미널 출력 | `PASS / FAIL / SKIP | 이름`, `RESULT:` 줄, exit 코드 | 중간 점검, 동결 후 |
| 화면 실패 증거 | `/tmp/e2e-shots/fail-NN.png` (과제 폴더 밖) | PNG 스크린샷 | e2e FAIL 직후 |
| 작업 이력 | `git log`, `git tag` | `<type>(R번호): 요약` + `확인: <명령> -> <결과>` | 언제든 |
| 사건·판단 기록 | `과제/AI_COLLABORATION.md` (원본 `templates/AI_COLLABORATION.md`) | 증상 → 재현 → AI 제안 → 판단 → 확인 → 커밋 | 사건마다 |
| 설계 결정 | `과제/docs/DECISIONS.md` | 근거·대안·가정·깨지는 입력 | 결정마다 |
| 세션 인계 | `과제/docs/HANDOFF.md` | 상태·다음 할 일 | 컨텍스트가 길어질 때 |
| 플랫폼 수집 | 시험 플랫폼 | 대화·터미널·git log 수집으로 알려짐 | [uncertain] |

최소 보완안(구현하지 않음): 검증 결과를 파일로도 남기려면 `bash scripts/verify.sh | tee /tmp/verify-$(date +%H%M).log`처럼 과제 폴더 밖에 저장합니다. 사건 로그에는 그 파일 이름을 적습니다.

---

## 4. 심사기준 매핑표 (가정한 일반 기준)

| 심사기준(가정) | 보여주는 단계 | 근거 | 충족도 | 보완 제안 |
| --- | --- | --- | --- | --- |
| 문제 적합성 | 1장, 단계 5~6 (계약·인터뷰) | `templates/TASK.md`(사실/가정/열린 질문/완료 조건), `.agents/skills/interview/SKILL.md`, `docs/prompts/02-interview.md` | 부분 | 키트는 절차만 제공합니다. 실제 적합성은 시연 때의 TASK.md와 합의문에서 드러납니다 [uncertain] |
| AI 활용의 타당성 | 단계 4~12, 6장 | `AGENTS.md`, `.agents/skills/`, `vendor/SOURCES.md`(채택·제외 이유), `docs/prompts/` | 충족 | 시연에서 AI 제안을 '수정·폐기'한 사례를 최소 1건 보여 줍니다 |
| 완성도 | V1~V9, 단계 8~11 | `tests/test_install.sh` 70건 통과, 설치·제거·검증 실행 결과 | 부분 | 키트는 검증됐지만, 가상 과제 앱의 완성도는 시연 전까지 미확인입니다 [uncertain] |
| 검증 가능성 | 3-2, 단계 9·11 | `scripts/verify_template.sh`(exit 0/1/2), `scripts/e2e_template.py`(exit 0/1/2/3), `docs/GIT_RULES.md` A3 커밋 본문 | 충족 | 결과를 파일로 남기는 `tee` 습관을 들입니다(3-3) |
| 설명 가능성 | 5장, 단계 10·12 | `docs/prompts/05-iterate.md` 3번(다섯 줄 설명), `docs/QA_PREP.md`, `.agents/skills/wrapup/SKILL.md` 6번(셀프 질문) | 부분 | 사용자의 직접 설명 연습은 문서로 보장되지 않습니다. 5-2 체크리스트를 소리 내어 확인합니다 |

미흡·부분 항목 정리:
- **문제 적합성·완성도:** 키트만으로는 증명되지 않습니다. 가상 과제를 실제로 끝까지 돌린 산출물(TASK.md, 커밋 이력, verify 결과)이 있어야 근거가 됩니다.
- **설명 가능성:** 문서와 프롬프트는 준비돼 있지만, 사용자가 자기 말로 설명할 수 있는지는 리허설에서만 확인됩니다.
- **로깅:** 파일 로그가 없어 시연 후 재확인이 어렵습니다. `tee` 보완안 정도로 충분합니다.

---

## 5. 이해 지원 단계

### 5-1. 단계별 설명

**단계 0~3. 기준점과 설치**
- 하는 일: 과제 초기 상태를 커밋하고, 키트를 과제 폴더 밖(`/tmp/kit`)에 받아 규칙·스킬·양식만 과제에 넣습니다.
- 왜 필요한가: 제가 만든 변경과 제공된 파일을 git으로 구분하고, 키트 원본이 제출물에 섞이지 않게 합니다.
- 직접 확인: `bash /tmp/kit/install.sh --check` 출력의 `충돌 0 건`, 설치 후 `ls .agents/skills | wc -l` → 19.
- 예상 질문: "남의 키트를 그대로 쓴 것 아닌가?" → 외부 스킬은 원문 그대로 라이선스와 함께 넣었고 출처·커밋은 `vendor/SOURCES.md`에 있습니다. 나머지 규칙·스킬은 직접 썼고 참고한 아이디어는 `NOTICE`에 적었습니다.

**단계 4. 로딩 확인**
- 하는 일: Codex가 규칙과 스킬을 실제로 읽었는지 확인합니다.
- 왜 필요한가: 이미 열린 세션에는 스킬이 반영되지 않을 수 있습니다(`docs/prompts/00-setup.md`).
- 직접 확인: `/skills` 목록. 안 보이면 경로 방식(`.agents/skills/kickoff/SKILL.md 를 읽고 그대로 따라`).
- 예상 질문: "스킬이 안 읽혔다면?" → 경로를 직접 지정하고, 15분 넘게 방해되면 `--remove`로 끄고 순정으로 진행합니다.

**단계 5. 계약서 ($kickoff)**
- 하는 일: README에서 사실·가정·열린 질문·안 할 일·완료 조건(R번호)을 나눕니다.
- 왜 필요한가: 코드를 쓰기 전에 무엇이 "완료"인지 확인 가능한 문장으로 정합니다.
- 직접 확인: `과제/docs/TASK.md`의 '사실'마다 README 근거 위치가 있는지.
- 예상 질문: "AI 요약을 믿었나?" → README는 제가 직접 읽고, AI에게 근거 문장을 인용하게 했습니다(`docs/prompts/01-kickoff.md` '아니면').

**단계 6. 인터뷰 ($interview)**
- 하는 일: 담당자에게 보낼 질문을 한 번에 하나씩 만들고, 답을 TASK.md에 반영해 합의문으로 닫습니다.
- 왜 필요한가: README에 없는 경계 조건(맞닿는 예약 허용 여부, 역할별 권한)이 결과를 바꿉니다.
- 직접 확인: TASK.md '합의'의 시각 기록, '만들지 않을 것'이 비어 있지 않은지.
- 예상 질문: "질문은 누가 했나?" → 제가 직접 보냈고 Codex는 문구만 만들었습니다(`AGENTS.md` 진행 2번).

**단계 7. 계획 ($plan)**
- 하는 일: 슬라이스를 나누고 R번호마다 확인 방법을 붙이고, 핵심 동작의 실패 경로를 표로 만듭니다.
- 왜 필요한가: "배정안 생성이 실패하면 기존 예약은?" 같은 질문에 설계 단계에서 답을 정합니다.
- 직접 확인: `과제/docs/FAILURE_MODES.md`의 다섯 행이 채워졌는지.
- 예상 질문: "실패하면 어떻게 되나?" → 원칙은 "실패하면 기존 결과를 보존하고 이유를 보여 준다"이고, 테스트로 고정했습니다(`templates/FAILURE_MODES.md` 첫 줄).

**단계 8~9. 최소 E2E와 화면 확인 ($slice, $e2e)**
- 하는 일: 예약 생성 한 줄기를 먼저 돌리고, 제가 Browser로 로그인·권한·새로고침·잘못된 입력·연타를 확인한 뒤 Playwright 시나리오로 옮깁니다.
- 왜 필요한가: 화면 확인이 늦으면 로그인 같은 문제가 후반에 드러납니다(`AGENTS.md` 환경 절).
- 직접 확인: `python3 scripts/e2e.py` 출력의 `E2E RESULT:` 줄. Playwright가 없으면 exit 3과 사람 확인 기록.
- 예상 질문: "Playwright가 없으면?" → 설치하지 않고 SKIP으로 남긴 뒤 사람이 확인합니다(`scripts/verify_template.sh` `check_e2e()`).

**단계 10. 반복 구현 ($slice)**
- 하는 일: R번호 하나씩 테스트 먼저 → 구현 → 실행 → 커밋. 의미 있는 변경 뒤에는 다섯 줄 설명을 받습니다.
- 왜 필요한가: 확인된 진척만 남기고, 제가 설명하지 못하는 코드를 쌓지 않습니다.
- 직접 확인: `git log --oneline`의 `feat(R2): …` 형식과 본문의 `확인:` 줄.
- 예상 질문: "배정 템플릿을 재사용하는 근거는?" → 기대는 가정과 깨지는 입력을 DECISIONS에 적고 테스트했습니다(`docs/prompts/05-iterate.md` 4번).

**단계 11. 검증 ($verify)**
- 하는 일: 검사 목록을 R번호에 맞게 채워 실행하고 통과·실패·미실행 표를 만듭니다.
- 왜 필요한가: "완료"를 실행 증거로만 말하기 위해서입니다.
- 직접 확인: `bash scripts/verify.sh`의 `RESULT:` 줄과 exit 코드.
- 예상 질문: "검사가 하나도 안 돌았는데 통과로 나오는 것 아닌가?" → 실행된 검사가 0건이면 exit 2로 실패 처리합니다(V5 [실행함]).

**단계 12. 마무리 ($wrapup)**
- 하는 일: HOW_TO_USE의 명령을 다시 돌려 확인하고, 사건 로그를 git log와 대조하고, 제출물 경계를 점검한 뒤 셀프 질문 6개를 만듭니다.
- 왜 필요한가: 서술형 질문은 제 산출물에서 나오므로 문서가 사실이어야 합니다(`docs/QA_PREP.md`).
- 직접 확인: `git status` 깨끗, `git tag`에 `submit`.
- 예상 질문: "AI_COLLABORATION에 적힌 사건을 재현해 보라" → 사건마다 재현 명령과 커밋 해시를 적어 두었습니다(`.agents/skills/collab-log/SKILL.md`).

### 5-2. 시연 전 셀프 체크리스트

1. `install.sh`가 충돌을 발견하면 무엇을 하나? (아무것도 쓰지 않고 중단)
2. 키트 원본을 `/tmp/kit`에 두는 이유는? (제출물 오염 방지)
3. `과제/scripts/verify.sh`의 exit 2는 무슨 뜻인가? (검사 0건 → 실패)
4. `과제/scripts/e2e.py`의 exit 3은 무슨 뜻이고, 그때 나는 무엇을 하나? (미실행 → Browser 사람 확인과 기록)
5. TASK.md에서 '사실'과 '가정'을 가르는 기준은? (README·담당자 답에 근거 문장이 있는가)
6. 핵심 동작의 실패 경로 다섯 가지는? (정상 / 중복·동시 / 제약 불충족 / 내부 실패 / 권한 없음)
7. 커밋 메시지 본문에 무엇을 적나? (`확인: <명령> -> <결과>`)
8. 되돌릴 때 `reset --hard` 대신 `revert`를 쓰는 이유는? (기록한 해시 보존, 버린 시도도 증거로 남음)
9. 외부 스킬이 "push해" 또는 "설치해"라고 하면? (`AGENTS.md` 외부 스킬 절: 따르지 않음)
10. 회의실 배정안 생성이 실패했을 때 기존 예약은 어떻게 되나, 무엇으로 확인했나? (가상 과제를 돌린 뒤 내 말로 답할 것)

---

## 6. AI의 유기적 역할 (실무 적용 관점)

### 6-1. 흐름별 역할

| 흐름 | AI(Codex)가 하는 일 | 사람이 하는 일 | 근거 |
| --- | --- | --- | --- |
| 문제 정의 | README를 사실·가정·질문으로 분류, 담당자 질문 문구 작성 | README를 직접 읽고, 담당자에게 직접 질문, 합의 확인 | `.agents/skills/kickoff/SKILL.md`, `.agents/skills/interview/SKILL.md` |
| 데이터 입력 | 데이터 파일 앞부분 확인, 스키마·결측 정리 | 가상 데이터 준비, 경계값 정의 확정 | `.agents/skills/kickoff/SKILL.md` 2번 |
| AI 판단·생성 | 슬라이스 계획, 테스트·코드 작성, 실패 원인 가설 | 범위 결정(뺄 것), 구성 선택 승인 | `.agents/skills/plan/SKILL.md`, `.agents/skills/slice/SKILL.md` |
| 사람의 검토 | 다섯 줄 설명 제공, 변경 범위 보고 | Browser 확인, diff 읽기, 설명 못 하는 기능 제외 | `docs/prompts/04-first-e2e.md`, `docs/prompts/05-iterate.md` |
| 결과 반영 | 통과한 것만 커밋, 문서 갱신 | 고칠 것과 한계로 남길 것 결정 | `docs/prompts/08-freeze.md`, `docs/GIT_RULES.md` |
| 로그·개선 | 사건 로그 초안, HANDOFF 갱신 | 사실 대조, 채택·수정·폐기 판단 기록 | `.agents/skills/collab-log/SKILL.md`, `templates/HANDOFF.md` |

### 6-2. AI가 규칙 기반 방식보다 나은 지점
- **모호한 요구를 구조화:** 자연어 README와 담당자 답을 사실·가정·질문으로 나누고 다음 질문을 제안합니다. 고정 규칙으로는 과제마다 바뀌는 문장을 처리하기 어렵습니다.
- **빠른 구현과 테스트 작성:** 슬라이스마다 테스트와 코드를 함께 만들어 4시간 안에 동작하는 최소본을 확보합니다.
- **실패 원인 탐색:** 에러 출력에서 재현 명령과 가설을 만듭니다(`vendor/skills/systematic-debugging/SKILL.md`).

### 6-3. 사람이 개입해야 하는 지점과 환각·오류 대응

| 위험 | 키트의 대응 | 사람의 개입 |
| --- | --- | --- |
| README에 없는 내용을 사실로 씀(환각) | '사실'은 출처 위치 필수, 없으면 '가정'(`.agents/skills/kickoff/SKILL.md` 3번) | 근거 인용 요청(`docs/prompts/01-kickoff.md`) |
| 돌리지 않고 "완료"라고 말함 | 실행 증거 없는 완료 금지, 0건은 실패(`AGENTS.md` 진행 4번, `scripts/verify_template.sh`) | 재실행 요청(`docs/prompts/06-stuck.md` B) |
| 추측한 선택자로 화면 테스트 | 실제 화면에서 선택자 확인(`.agents/skills/e2e/SKILL.md` 2번) | 제가 Browser로 먼저 확인 |
| 같은 실패 반복 | 2번이면 멈추고 보고(`AGENTS.md` 진행 6번) | 범위 축소 결정(`docs/prompts/06-stuck.md` E) |
| 과설계 | `vendor/skills/ponytail/SKILL.md`, `.agents/skills/plan/SKILL.md` 과설계 금지 | 계획에서 직접 쳐냄 |
| 설치·외부 접속 시도 | `AGENTS.md` 환경 절 | Esc로 끊고 대안 요청 |
| 권한 검사 누락 | 처리 함수에서 검사(`AGENTS.md` 기록 절), `vendor/skills/security-and-hardening/SKILL.md` | 다른 역할로 API 직접 호출 확인 |

---

## 7. 시연 진행안 (약 25분)

목적: 키트가 "작게, 확인하면서, 기록을 남기며" 과제를 풀게 만드는지 보여 줍니다. 가상 과제 앱을 처음부터 다 만드는 대신, 키트의 결정적 동작(설치·검증·끄기)은 실제로 실행하고, Codex 단계는 앞 3단계와 슬라이스 하나만 실시간으로 보여 줍니다. 전체 90분 리허설은 `docs/RUNBOOK.md` 시각표를 비율로 줄여 따로 합니다.

**준비물**
- Codex를 쓸 수 있는 웹 IDE 또는 로컬 환경, Chrome
- 빈 과제 폴더와 1-1의 README·CSV 세 개
- 이 레포 clone(`/tmp/kit`)
- 미리 만들어 둔 결과물 한 벌(리허설에서 나온 TASK.md, git log, verify 출력). 실시간 진행이 막힐 때 씁니다.

| 시간 | 단계 | 실행 | 기대 출력 | 실패 시 대응 |
| --- | --- | --- | --- | --- |
| 0:00–2:00 | 소개 | 이 문서 '먼저 알아 둘 것'과 2-1 도식 | — | — |
| 2:00–5:00 | 설치 | `git init` → 기준점 커밋 → `bash /tmp/kit/install.sh --check --extras core,web` → 같은 명령에서 `--check` 빼고 실행 | `충돌 0 건`, `설치 완료: 스킬 19개` | 충돌이 나면 그 줄을 보여 주고 "아무것도 쓰지 않았다"는 안전장치로 설명 |
| 5:00–6:30 | 환경 점검 | `bash /tmp/kit/scripts/preflight.sh` | Playwright 유무, 포트 비어 있음 | 이 출력이 이후 구성 선택의 근거라고 설명 |
| 6:30–8:00 | 안전장치 | `bash scripts/verify.sh` (목록 비움) | `실행된 검사 0건: 실패로 처리`, exit 2 | — |
| 8:00–12:00 | 계약 | Codex 새로 열기 → `/skills` → `docs/prompts/01-kickoff.md` 프롬프트 | `과제/docs/TASK.md`, 열린 질문 5개(맞닿는 시간, 정기회의 우선순위 등) | 스킬이 안 보이면 경로 방식. 응답이 늦으면 준비한 TASK.md로 대체 |
| 12:00–15:00 | 인터뷰 | `docs/prompts/02-interview.md` 1번 → 가상 담당자 답 "끝과 시작이 같으면 허용" 입력 → 2번 | TASK.md '사실'이 바뀌고 다음 질문 하나 | 담당자 역할은 진행자가 직접 맡음 |
| 15:00–21:00 | 슬라이스 하나 | `docs/prompts/04-first-e2e.md` 1번 (예약 생성·중복 거부만) | 실패 → 통과하는 테스트 출력, `feat(R1): …` 커밋 | 6분을 넘기면 중단하고 준비한 git log로 설명 |
| 21:00–23:00 | 검증 | 검사 목록에 R1 한 줄을 채우고 `bash scripts/verify.sh` → 목록 없이 `python3 scripts/e2e.py --check` | `RESULT: PASS 1 / FAIL 0`, e2e는 exit 0 또는 3 | exit 3이면 "설치하지 않고 사람 확인으로 돌린다"고 설명 |
| 23:00–24:30 | 기록 | `git log --oneline`, `과제/AI_COLLABORATION.md` | 기준점·설치·R1 커밋, 사건 로그 | 사건이 없으면 빈 양식을 보여 주고 형식만 설명 |
| 24:30–25:00 | 끄기 | `bash /tmp/kit/install.sh --remove` | 블록·스킬 삭제, 작업 문서 유지 | — |

---

## 남은 불확실성 [uncertain]

- Codex가 `.agents/skills`를 실제로 인식하는지, 스킬 19개를 로딩할 때 컨텍스트 부담이 어떤지
- Codex가 각 프롬프트에 기대한 형식으로 답하는지(단계 4~12의 출력 전부)
- 시험 플랫폼이 대화·터미널·git log를 어떻게 수집하고 평가에 쓰는지
- 시험 환경에 Python Playwright와 브라우저가 있는지(없으면 V7 경로로 진행)
- 심사기준 원문(4장은 가정한 일반 기준)
- 가상 과제(회의실 예약) 앱의 완성도와 verify 결과(V11, V12)
