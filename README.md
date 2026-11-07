# Reels Watch

Apple Watch용 릴스 뷰어.

- 제스처 스펙: [docs/GESTURES.md](docs/GESTURES.md)

## 구조

```
ReelsWatch/
  App/       앱 진입점 (데이터 소스는 여기서 주입)
  Models/    Reel, ReelComment, DMThread, Page
  Data/      ReelsProvider 프로토콜 + MockReelsProvider
  ViewModels/ ReelsViewModel (화면 상태, 스와이프 라우팅, 낙관적 좋아요)
  Views/     ReelScreen, CommentsOverlay, ShareSheet, ReelPosterView
  Support/   SwipeIntent, Formatting, Haptics
ReelsWatchTests/
```

UI는 `ReelsProvider` 프로토콜에만 의존한다. 지금은 `MockReelsProvider`를 쓰고,
실제 데이터 소스는 나중에 구현체만 교체해서 붙인다.

## 빌드 (macOS + Xcode 15+)

프로젝트 파일은 [XcodeGen](https://github.com/yonaskolb/XcodeGen)으로 생성한다.

```sh
brew install xcodegen
xcodegen generate
open ReelsWatch.xcodeproj
```

번들 ID는 `com.redbridgecompany.reelswatch` (`project.yml`).

## 진행 상황

- [x] 1. 프로젝트 구조, `ReelsProvider`, 목업 구현체, 단위 테스트
- [x] 2. 영상 화면 → 댓글창(토글, 용두 스크롤, 하트) → DM 공유 화면 (영상은 자리표시 화면, 시뮬레이터/실기기 확인 필요)
- [ ] 3. 폰 앱 로그인 + 실제 데이터 소스 연동
