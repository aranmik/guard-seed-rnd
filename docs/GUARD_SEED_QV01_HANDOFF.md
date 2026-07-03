# Guard Seed × Quarterview R&D — QV01H Handoff

> Guard Seed QV01H — Possibility Verified / First Boss Duel Feel Verified

이 문서는 QV01H 시점의 세계선을 고정하는 기준 문서다. 새 세션/새 작업자는 이 문서부터 읽는다.

---

## 1. 프로젝트 현재 상태

- **프로젝트명**: Guard Seed × Quarterview R&D
- **현재 기준 빌드**: QV01H
- **현재 라이브 URL**: https://aranmik.github.io/guard-seed-rnd/
- **현재 최신 커밋**: `d8da047` — `feat: clarify boss parry chain and guard feedback`
- **상태**: 핸드폰 실기에서 가능성/재미 확인 완료
- **현재 판단**: "된다. 재미있다. 이제 찬찬히 맛있게 만들 단계."

## 2. 핵심 게임 감정

- 3개의 전장을 관찰한다
- 위험한 전장을 선택한다
- 같은 전장을 다시 탭해 방패 영웅으로 개입한다
- 직접 Guard / Parry / Miss 타이밍을 수행한다
- 결과가 선택 전장에만 돌아간다
- 보스 이벤트에서는 보스 리듬을 모두 Perfect Parry하면 "나의 찬스다!!!!"가 열리고, 터치 연타로 반격한다

핵심 문장:

> "위험 전선을 읽고, 내가 직접 막고, 완벽히 막으면 내 턴을 만든다."

## 3. 현재 구현 요약

- **QV01B**: 모바일 Pages 플레이 가능, 개입 레이어 시인성 조정
- **QV01C**: 모바일 화면 고정, 레이어 정리, FEEL DEV, Parry Fever 1차
- **QV01D**: 몬스터별 패턴 프로파일, 2.5D 전장 배치, 일반전 Fever OFF
- **QV01E**: FEEL RECORDER, Copy/Save/Load/Snapshot
- **QV01F**: 오우거 보스 1:1 듀얼, 보스 패턴 A/B, Perfect Parry Chance
- **QV01G**: 보스전 읽힘, 링 디자인, Beat marker, 페이즈 결과
- **QV01H**: 폰 기준 튜닝 노트, 멈추는 링 힌트, Guard early/late, PERFECT CHAIN 강화

## 4. 현재 플레이 흐름

### 일반 전장

1. 타이틀
2. 3전장 관찰
3. 전장 탭 선택
4. 같은 전장 재탭 → 개입
5. 방패 영웅 등장
6. 링 수렴
7. Guard / Perfect / Miss
8. 결과 포즈
9. 선택 전장에만 결과 반영
10. 관찰 화면 복귀

### 보스 이벤트

1. 보스 전조 또는 DEV 테스트("⚔ 보스와 맞선다" / DEV BOSS DUEL TEST)
2. Ogre Duel A / B
3. 패턴 텔레그래프("2연타 후 — 강타가 온다" 등)
4. Heavy / Rapid / Finish 링
5. Beat marker (● ● ◆)
6. 전타 Perfect Parry 성공 시 Chance
7. "나의 찬스다!!!!"
8. 터치 연타
9. 보스 위압도 감소 / 결과 패널
10. Duel 다시 / 전장 복귀

## 5. 중요한 설계 원칙

- 폰 실기 기준이 최종 기준이다
- 노트북 프리뷰 손맛은 참고만 한다
- 일반 전선 Fever는 기본 OFF
- Chance/Fever는 보스/이벤트 전용 핵심 보상으로 본다
- Guard는 실패는 아니지만 Perfect 실패다
- Guard는 "막았지만 빈틈을 만들지 못했다"로 읽혀야 한다
- 멈추는 링/훼이크 링은 반드시 힌트가 있어야 한다
- 결과는 선택 전장에만 돌아가야 한다
- 연타 입력이 다음 UI로 새면 안 된다
- 화면은 모바일 고정, 스크롤/슬라이스 금지
- 외부 의존성 0 유지
- `_incoming` push 금지
- 회사/외부 자료 혼입 금지

## 6. 현재 FEEL DEV / FEEL RECORDER

### FEEL DEV에서 조정 가능한 값

- Ring Speed
- Parry Window
- Guard Window
- Pose Hold
- Hitstop
- Input Lock
- Screen Shake
- Fever Duration

### FEEL RECORDER 기능

- Copy Current
- Copy All
- Save / Load
- "이 값 좋음" Snapshot
- Snapshot Apply / Delete

### localStorage key

- `gsqv01_feel_working`
- `gsqv01_feel_snapshots`

나라가 폰에서 값을 찾은 뒤 **Copy Current로 값을 전달**하면, 다음 패스에서 그 값을 기본값으로 고정할 수 있다. (튜닝 기록은 [GUARD_SEED_QV01_TUNING_NOTES.md](GUARD_SEED_QV01_TUNING_NOTES.md)에 남긴다.)

## 7. 현재 보스 패턴

### Boss Pattern A — "팡팡…팡!"

- 2연타 후 긴 뜸
- 마지막 강타
- 묵직한 보스 패턴

### Boss Pattern B — "파파파파파팡!"

- 빠른 연속 압박
- 마지막 강타
- 전설적인 연속 패리 감각을 목표로 하는 패턴

### Perfect Chain

- 전타 Perfect Parry 성공 시만 Chance
- Guard/Miss가 하나라도 있으면 Chain Broken
- Guard는 막았지만 빈틈을 만들지 못한 상태

### Chance

- "나의 찬스다!!!!"
- step-in
- 터치 연타
- 검 휘두르기 / 보스 밀림

### 결과

- Perfect / Partial / Fail 결과 패널

## 8. 다음 작업 후보

1. **핸드폰 기준 패턴값 튜닝** — 오우거 / 고블린 / 오크메이지 / Boss A / Boss B 값 확정
2. **보스 Chance 연타 맛 강화** — 검 휘두르기 / 타격감 / 보스 반응 / "내 턴이다" 감정 강화
3. **보스 링 디자인 추가 정리** — 일반 / Rapid / Heavy / Finish / Feint 문법
4. **3전장 생동감 강화** — 전장이 실제로 싸우는 느낌, 위험 전장이 왜 위험한지 보이게, 아군/몬스터가 더 살아 움직이는 느낌
5. **짧은 1판 루프 만들기** — 3전장 개입 몇 회 → 보스 전조 → 보스 듀얼 → 결과 → 다시 시작
6. **키아트/타이틀/보스 전조 연출 정리**
7. **아군/몬스터별 역할 감정 정리**

## 9. 실행 / 배포 방법

### 로컬 실행

```
py -m http.server 5180 --bind 0.0.0.0
```

로컬 URL: `http://localhost:5180/`

폰 로컬 테스트: `http://<PC_IP>:5180/`

### GitHub Pages

`https://aranmik.github.io/guard-seed-rnd/`

### 배포 절차

```
git add ...
git commit -m "..."
git push
```

push 후 Pages 반영 대기 1~3분.

## 10. 이어받기용 짧은 프롬프트

다음 세션에서 그대로 붙여넣을 수 있는 프롬프트:

> 유키야, Guard Seed QV01H 이어서 하자. repo는 aranmik/guard-seed-rnd, Pages는 https://aranmik.github.io/guard-seed-rnd/ 이고, 최신 기준은 docs/GUARD_SEED_QV01_HANDOFF.md야. 현재 가능성/재미 확인 완료했고, 다음은 폰 기준 손맛 튜닝 또는 보스 Chance 맛 강화부터 이어가면 돼.
