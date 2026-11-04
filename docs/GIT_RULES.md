# 형상관리 규칙

두 부분으로 나눕니다. A는 시험 중 과제 폴더 규칙이고, 요지가 AGENTS 블록과 스킬에 들어가 있습니다. B는 이 키트 레포 자체의 관리 규칙입니다.

git log는 평가 기록에 남습니다. 커밋 이력은 '확인된 진척만 남겼다'는 증거이고, AI_COLLABORATION.md가 커밋 해시를 근거로 인용합니다. 그래서 이력을 깨끗하게 쌓고, 한 번 쓴 해시는 바꾸지 않습니다.

---

## A. 시험 중 (과제 폴더)

### A1. 시작 (설치 전)
```bash
git status 2>/dev/null || git init
git config user.name  "<이름>"        # --global 쓰지 않음 (전역 설정 수정 금지)
git config user.email "<메일>"
git add -A && git commit -m "chore: 과제 초기 상태"      # 제공된 파일만 있는 기준점
```
- 이미 git 이력이 있으면 init하지 않고, 제공된 커밋은 건드리지 않는다.
- 기준점 커밋은 키트 설치와 작업 전에 만든다. 내가 만든 변경과 제공된 파일을 구분하려는 것이다.
- 키트 설치 직후 한 번 더 커밋한다: `chore: cofa-kit 설치 (<키트 커밋 7자리>)`.

### A2. 브랜치
- 기본 브랜치 하나로 작업한다. 4시간 과제에서 브랜치 전환은 혼선만 만든다.
- 두 번째 Codex 탭은 서로 다른 파일만 맡기고, 커밋은 메인 탭에서만 한다.
- 실험은 브랜치 대신 `git stash` 또는 되돌리기로 처리한다.

### A3. 커밋 단위와 메시지
- 커밋 하나는 확인된 슬라이스 하나다. 테스트나 확인 명령이 통과한 뒤에 커밋한다.
- 형식:
  ```
  <type>(<R번호>): <무엇을 했나, 한 줄>

  확인: <명령> -> <결과 요약>
  미확인: <안 돌린 것, 없으면 생략>
  ```
- type: `feat` 기능, `fix` 버그 수정, `test` 테스트만, `docs` 문서(산출물 3종 포함), `refactor` 동작 불변 정리, `chore` 설정·설치, `wip` 미확인 저장.
- 예: `feat(R2): 운영자 노선 생성 API` / 본문 `확인: python3 -m unittest tests.test_routes -> 6 tests OK`.
- 문서만 갱신하면 `docs: AI_COLLABORATION E3 추가`처럼 따로 커밋해도 된다.

### A4. 무엇을 커밋하나
- `git add`에는 경로를 지정한다. `git add -A`는 A1 기준점처럼 `git status`를 본 뒤에만 쓴다.
- 커밋 전에 `git status --short`와 `git diff --stat`을 본다.
- 커밋하지 않는 것: `.env`와 비밀번호·키, `venv/`·`node_modules/`, `__pycache__/`, 로그, `/tmp/e2e-shots` 같은 스크린샷, 큰 데이터 복사본. 키트 설치기가 `.gitignore` 기본값을 만든다(이미 있으면 그대로 둠).
- DB 파일은 초기화 스크립트로 다시 만들 수 있을 때만 제외한다. 그렇지 않으면 HOW_TO_USE의 실행법이 깨진다.

### A5. 저장 주기와 장애 대비
- 늦어도 20~30분마다 커밋한다. 첫 최소 E2E는 80분 안에 커밋한다.
- 확인 전인데 끊길 것 같으면 `wip(미확인): <내용>`으로 저장하고, 다음 커밋에서 확인 결과를 적는다. wip를 확인된 것처럼 기록하지 않는다.
- 재접속하면 `git log --oneline -5`와 `git status`부터 본다.

### A6. 되돌리기
| 상황 | 명령 |
| --- | --- |
| 커밋 전 파일 변경 취소 | `git restore <파일>` |
| 스테이징 취소 | `git restore --staged <파일>` |
| 실험을 잠시 치우기 | `git stash push -m "<이유>"` / `git stash pop` |
| 커밋한 변경 취소 | `git revert <해시>` (이력 보존) |

- 금지: `git reset --hard`, `git rebase`, `git commit --amend`, `git push --force`. AI_COLLABORATION에 적은 해시가 사라지고, 무엇을 버렸는지 증거도 사라진다.
- 버린 시도는 revert 커밋과 AI_COLLABORATION의 '폐기'로 남긴다. 서술형 재료가 된다.

### A7. 이정표 태그 (로컬만)
| 태그 | 시점 |
| --- | --- |
| `m1-e2e` | 최소 E2E가 돌고 Browser 확인을 마쳤을 때 |
| `freeze` | 기능 동결 시각 |
| `submit` | 제출 확정 직전 마지막 커밋 |

```bash
git tag -a m1-e2e -m "최소 E2E + Browser 확인"
```
- `git push`는 어떤 형태로도 하지 않는다(태그 포함).

### A8. 제출 전 점검 ($wrapup)
- `git status`가 깨끗한가(남은 변경은 커밋하거나 의도적으로 버렸나).
- `git log --oneline`이 AI_COLLABORATION 사건 로그의 해시와 맞는가.
- 제출물에 키트 원본, 임시 파일, 비밀값이 섞이지 않았는가.

---

## B. 이 키트 레포 (taehyeong51/26_skhynix_hackerthon)

### B1. 브랜치
- `main`: 시험 당일 clone하는 배포본. 항상 `bash tests/test_install.sh`가 통과하는 상태.
- 작업은 다른 브랜치에서 하고 테스트가 통과하면 `main`에 반영한다(fast-forward).

### B2. 커밋 메시지
- `feat:` 스킬·스크립트 추가, `fix:` 버그, `docs:` 문서, `vendor: update <스킬> to <커밋>` 외부 스킬 갱신, `test:` 테스트.
- vendor 폴더의 원문은 수정하지 않는다. 바꿀 것은 키트 AGENTS 블록 쪽에 규칙으로 둔다.

### B3. 동결과 공개
- 시험 당일 16:00에 `main`에 태그 `exam-YYYYMMDD`를 붙이고 이후 수정하지 않는다.
- 그 커밋 해시를 메모해 과제의 AI_COLLABORATION.md '사용한 공개 자료'에 적는다.
- 2차 결과 통지 전까지 레포를 Public으로 둔다.

### B4. 들어가면 안 되는 것
- 시험 문제 내용(10/31 셔틀 과제 포함), 과제용 앱 코드나 스타터, 비밀값, 전역 설정을 바꾸는 스크립트.
