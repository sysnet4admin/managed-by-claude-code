# BetterDisplay 설정

macOS 디스플레이 해상도 및 화면 관리 도구인 BetterDisplay의 설정을 Mac 간에 동일하게 유지하기 위한 스크립트.

## 설치

[BetterDisplay 공식 사이트](https://betterdisplay.pro) 또는 Homebrew로 설치:

```bash
brew install --cask betterdisplay
```

## 새 Mac에서 설정 적용

1. BetterDisplay 설치
2. 라이선스 키 입력 (별도 관리)
3. 아래 스크립트로 UI 설정 일괄 적용:

```bash
./apply-settings.sh
```

4. BetterDisplay 재시작

## 포함된 설정

- 자동 업데이트 비활성화
- 메뉴 항목 표시 레벨 (less/more/hide)
- UI 레이아웃 설정

## 포함되지 않는 설정 (기기별 수동 설정)

- 라이선스 키
- 디스플레이 해상도/모드 설정
- 밝기, 색상 캘리브레이션 값
- 디스플레이 하드웨어 식별자
