---
name: stageshow
description: 제품 소개용 가짜 화면(faux product UI) 스틸이나 커서 데모 애니메이션을 만들 때, 또는 실제 화면의 시각 위계·여백·문구 절제를 다듬을 때 쓴다. 원본은 /tmp/kit-extras/stageshow (benjitaylor/skills, MIT, 커밋 8020574). 과제의 실제 서비스 화면을 이 키트의 가짜 UI로 대체하지 않는다.
---

# stageshow (키트 연결용 안내)

원본 스킬은 과제 폴더 밖 `/tmp/kit-extras/stageshow`에 있다. 없으면 사용자에게 `bash /tmp/kit/scripts/fetch_stageshow.sh` 실행을 요청한다.

## 언제 쓰나
- 과제가 소개 화면, 랜딩 히어로, 기능 카드 그림, 사용 흐름 데모 애니메이션을 요구할 때: 원본 `SKILL.md`의 Workflow를 따른다.
- 실제 서비스 화면을 다듬을 때: 원본 `references/craft.md`(Restraint, Spacing and alignment, Icons and logos)와 `references/framing.md`의 규칙만 가져온다. 진짜 데이터·진짜 동작은 그대로 둔다.

## 제약 (키트 AGENTS 블록이 우선)
- React 키트와 예제 실행에는 npm 의존성이 필요하다. `npm install`은 하지 않는다. 의존성이 이미 없으면 문서 규칙만 쓴다.
- `assets/app-icons.ts`와 `kit/brands`의 상표·앱 아이콘 그림은 MIT 범위 밖이다(원본 NOTICE.md). 제출물에 복사하지 않는다.
- 원본 폴더 전체를 과제 폴더로 복사하지 않는다. 필요한 컴포넌트 코드만, 이해하고 설명할 수 있는 만큼 옮기고 출처를 AI_COLLABORATION.md '사용한 공개 자료'에 적는다.
- 데모용 가짜 화면은 HOW_TO_USE.md에 '데모(가짜 데이터)'로 표시한다.
