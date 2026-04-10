#!/bin/bash

# BetterDisplay 설정 적용 스크립트
# 목적: 새 Mac에서 동일한 BetterDisplay UI 구성 및 앱 설정 적용
# 주의: 디스플레이 하드웨어 설정(해상도, 캘리브레이션)은 기기마다 다르므로 포함하지 않음

DOMAIN="pro.betterdisplay.BetterDisplay"

echo "BetterDisplay 설정 적용 중..."

# 자동 업데이트 비활성화
defaults write $DOMAIN SUAutomaticallyUpdate -bool false
defaults write $DOMAIN SUEnableAutomaticChecks -bool false
defaults write $DOMAIN SUSendProfileInfo -bool false

# 메뉴 항목 레벨 설정 (less/more/hide)
defaults write $DOMAIN menuLevelBlueLight -string "less"
defaults write $DOMAIN menuLevelBrightness -string "less"
defaults write $DOMAIN menuLevelCheckForUpdates -string "less"
defaults write $DOMAIN menuLevelColorDepth -string "more"
defaults write $DOMAIN menuLevelColorMode -string "more"
defaults write $DOMAIN menuLevelColorProfile -string "more"
defaults write $DOMAIN menuLevelConfigProtection -string "more"
defaults write $DOMAIN menuLevelContrast -string "hide"
defaults write $DOMAIN menuLevelDDCAdjustments -string "more"
defaults write $DOMAIN menuLevelDDCInput -string "more"
defaults write $DOMAIN menuLevelDisplayConnect -string "less"
defaults write $DOMAIN menuLevelDisplayDisconnect -string "more"
defaults write $DOMAIN menuLevelDisplayMode -string "more"
defaults write $DOMAIN menuLevelDisplaysAndVirtualScreens -string "less"
defaults write $DOMAIN menuLevelGroups -string "less"
defaults write $DOMAIN menuLevelImageAdjustments -string "more"
defaults write $DOMAIN menuLevelManageDisplay -string "more"
defaults write $DOMAIN menuLevelManageVirtualScreen -string "more"
defaults write $DOMAIN menuLevelMirror -string "more"
defaults write $DOMAIN menuLevelMove -string "more"
defaults write $DOMAIN menuLevelPIP -string "more"
defaults write $DOMAIN menuLevelQuit -string "less"
defaults write $DOMAIN menuLevelRefreshRate -string "more"
defaults write $DOMAIN menuLevelResolution -string "less"
defaults write $DOMAIN menuLevelRotation -string "more"
defaults write $DOMAIN menuLevelSettings -string "less"
defaults write $DOMAIN menuLevelStream -string "more"
defaults write $DOMAIN menuLevelToggles -string "more"
defaults write $DOMAIN menuLevelVideoFilterWindow -string "less"
defaults write $DOMAIN menuLevelVirtualScreenConnect -string "less"
defaults write $DOMAIN menuLevelVirtualScreenDisconnect -string "more"
defaults write $DOMAIN menuLevelVolume -string "more"
defaults write $DOMAIN menuLevelXDRPreset -string "more"

# 기타 UI 설정
defaults write $DOMAIN toolsMenuCollapsed -bool true
defaults write $DOMAIN onboardingMenuIcon -bool false
defaults write $DOMAIN onboardingSettingsIcon -bool false

echo "완료. BetterDisplay를 재시작하면 설정이 적용됩니다."
echo ""
echo "참고: 라이선스 키 및 디스플레이 하드웨어 설정은 수동으로 입력하세요."
