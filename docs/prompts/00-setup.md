# 00 설치와 로딩 확인

## 언제
19:00. 감독 준비를 마치고 과제 폴더 터미널이 열린 직후, 5분 안에 끝냅니다.

## 터미널 명령
한 줄씩 실행합니다. 이미 과제에 git 이력이 있으면 처음 세 줄은 건너뜁니다.

```bash
git status 2>/dev/null || git init
```
```bash
git config user.name "<이름>" && git config user.email "<메일>"
```
```bash
git add -A && git commit -qm "chore: 과제 초기 상태"
```
```bash
git clone https://github.com/taehyeong51/26_skhynix_hackerthon /tmp/kit
```
```bash
bash /tmp/kit/install.sh --extras core,web
```
```bash
git add -A && git commit -qm "chore: cofa-kit 설치"
```
```bash
bash /tmp/kit/scripts/preflight.sh
```

설치기가 충돌로 멈추면 아무것도 쓰지 않은 상태입니다. 출력의 `충돌` 줄을 읽고 해당 파일만 확인하세요. clone이 막히면 키트 없이 진행하고 DECISIONS에 한 줄 남깁니다.

## 프롬프트
Codex를 이 폴더에서 **새로** 연 뒤 `/status`, `/model`, `/skills`를 먼저 눌러 봅니다. 그다음:

```
이 폴더에서 아래만 확인해서 한 줄씩 답해. 파일은 수정하지 마.
1. 지금 적용된 AGENTS.md 규칙의 첫 줄과, 인식된 스킬 이름 목록
2. 이 세션이 쓰는 모델 이름
3. python3 --version 과 git status --short 의 결과
```

## 정상이면
- 스킬 목록에 키트 8개(kickoff interview plan slice e2e verify collab-log wrapup)와 설치한 외부 스킬이 보입니다.
- git status가 깨끗합니다.
- preflight에서 쓸 수 있는 웹 패키지, 포트, Playwright 유무를 메모했습니다.

## 아니면
스킬이 안 보일 때(이미 열린 세션이었을 가능성이 큽니다). 새 세션을 한 번 더 열어 보고, 그래도 안 되면 이후 모든 프롬프트 앞에 경로 방식을 씁니다.

```
.agents/skills/kickoff/SKILL.md 를 읽고 그대로 따라. 이후 단계도 같은 방식으로 .agents/skills/<이름>/SKILL.md 를 읽고 따라.
```

키트가 15분 넘게 방해될 때:

```bash
bash /tmp/kit/install.sh --remove
```

그리고 Codex에게 이렇게 말합니다.

```
키트를 껐어. docs/DECISIONS.md에 '키트 제거: <이유>' 한 줄만 남기고, 앞으로는 순정 방식으로 진행해.
```

## 다음
[01-kickoff](01-kickoff.md)
