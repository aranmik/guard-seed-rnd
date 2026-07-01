# guard-seed-rnd

가드 시드(Guard Seed) R&D 리포지토리. 3전선 관찰 → 위험 전선 선택 → 방패 영웅 개입
→ 중앙 수렴 타이밍 Guard/Parry/Miss → 결과가 선택 전선에 반영되는 손맛을 실험한다.

## 현재 산출물

### Quarterview R&D 01 (QV01 / 01A)
- **`quarterview01_guard_intervention_proto.html`** — 프로토타입 (단일 HTML + 상대경로 자산).
  타이틀(키아트) → 3전장 쿼터뷰 관찰(전장 몰입·하단 시스템 UI 없음) → 전선 탭 선택
  → 재탭 개입 → 방패 개입 화면(**나 중심**·화면 탭 1개로 Guard/Parry/Miss 타이밍 판정·3연타 finish)
  → 결과 전선 반영 → 보스 전조(키아트)까지. 실제 PNG 리소스 사용.
- **01A 패스 요약**: 타이틀/보스를 완성형 키아트(`guardseed_title`/`guardseed_boss`)로 교체,
  관찰 화면 하단 시스템 패널 제거(전선이 바닥까지), 조작을 **2탭(탭=선택·재탭=개입)** 으로 단순화,
  개입 레이어에서 몬스터·Guard/Parry 버튼 제거(화면 탭 통합), 몬스터 체급 차등(고블린<오크메이지<오우거),
  스프라이트 시트에서 idle/action 프레임을 뽑아 전선 행동감(공격 프레임 전환) 보강.

## 폴더 구조

```
guard-seed-rnd/
├─ quarterview01_guard_intervention_proto.html   ← QV01/01A 프로토타입
├─ assets/qv01/                                  ← HTML이 런타임에 참조하는 최적화 자산
│  ├─ backgrounds/  (레인 4종, 불투명, 다운스케일)
│  ├─ ui/           (guardseed_title / guardseed_boss — 완성형 키아트, 불투명)
│  ├─ allies/       (warrior/archer/mage/priest — 크로마키 컷아웃: anchor + idle/act 프레임)
│  ├─ enemies/      (goblin/ogre/orc_mage — 크로마키 컷아웃: anchor + idle/act 프레임)
│  └─ player/       (방패 영웅 상황별 포즈 — 크로마키 컷아웃)
├─ tools/
│  ├─ optimize_assets.ps1                        ← QV01 자산 최적화(anchor/배경)
│  └─ optimize_assets_01a.ps1                    ← 01A 키아트 + 시트 프레임 추출(정렬)
└─ _incoming/                                    ← 원본 입력 자료(읽기전용 보존)
   ├─ qv01/  (첨부 노트 + guard_seed_quarterview_assets_v01 원본 PNG·매니페스트)
   └─ qv01a/ (guardseed_title.png / guardseed_boss.png 키아트 원본)
```

## 자산 파이프라인

원본 캐릭터 PNG는 **마젠타(R~250 G~2 B~248) 크로마키 배경**을 깔고 있어 그대로 레인 위에
올릴 수 없다. `tools/optimize_assets.ps1`(PowerShell + System.Drawing, LockBits)이:

1. 마젠타 → 투명 알파 키 아웃 + 경계 헤일로 despill
2. 콘텐츠 바운딩박스로 트림
3. 모바일(390px)용 다운스케일

을 수행해 `assets/qv01/`로 출력한다. 배경 PNG는 불투명 씬 아트라 리사이즈만 한다.
외부 도구(ImageMagick/Python/sharp) 없이 순수 PowerShell로 처리한다.

**01A 시트 프레임 추출**(`optimize_assets_01a.ps1`): 5-pose 시트(idle/action/walk/hit/dead)는
프레임 간격이 불균등해 5등분 슬라이스가 어긋난다. 그래서 **마젠타 세로 갭 자동 세그멘테이션**
(컬럼별 non-마젠타 픽셀 카운트로 프레임 경계 검출·무기가 갭을 잇는 문제는 content 임계값을 높여 회피)
으로 프레임을 잘라내고, idle 프레임 기준 스케일로 **동일 캔버스에 바닥 정렬**해 idle↔action
스왑 시 몸 크기·위치가 튀지 않게 출력한다. 키아트(title/boss)는 불투명이라 다운스케일만.

재생성:

```powershell
powershell -ExecutionPolicy Bypass -File tools/optimize_assets.ps1       # QV01 anchor/배경
powershell -ExecutionPolicy Bypass -File tools/optimize_assets_01a.ps1   # 01A 키아트/프레임
```

## 플레이 (GitHub Pages)

`main` 브랜치를 GitHub Pages(Deploy from a branch · `/root`)로 배포하면 폰에서 바로 플레이:

```
https://<GITHUB_ID>.github.io/guard-seed-rnd/
```

루트 `index.html`이 최신 프로토타입으로 자동 이동한다. 직접 주소:

```
https://<GITHUB_ID>.github.io/guard-seed-rnd/quarterview01_guard_intervention_proto.html
```

모든 자산은 상대경로(`assets/qv01/…`)라 Pages 하위경로에서 그대로 로드된다.

## 로컬 프리뷰

정적 서버 루트를 이 폴더로 두고 `index.html`(또는 QV01 파일)을 연다.
(예: `.claude/launch.json`의 `guard-seed-rnd` = 포트 **5180** — 이 launch.json은 개인 환경 파일이라 배포에 포함하지 않는다.)

## 보호 규칙

- `seed02c7_triple_guard_finish_polish.html`(C7)은 손맛/구조 **참고 전용** — 절대 수정·덮어쓰기 금지.
  (본 QV01 세션 시점에는 repo/다운로드에 C7 실파일이 없어, 첨부 노트의 손맛 서술을 기준으로 재현했다.)
- 외부 CDN/URL/라이브러리 금지. 성장/보상/장비/스킬트리/저장/실제 보스전 금지.
- `_incoming/`의 원본 입력 자료는 읽기전용으로 보존한다.
