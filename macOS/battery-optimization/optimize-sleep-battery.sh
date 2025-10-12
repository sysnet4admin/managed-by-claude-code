#!/bin/bash

# macOS 잠자기 모드 배터리 최적화 스크립트
# 실행 전 sudo 권한이 필요합니다

set -e

echo "🔋 macOS 잠자기 모드 배터리 최적화 시작"
echo "=========================================="
echo ""

# 현재 설정 백업
echo "📋 현재 설정 백업 중..."
pmset -g > ~/macos_power_settings_backup_$(date +%Y%m%d_%H%M%S).txt
echo "✅ 백업 완료: ~/macos_power_settings_backup_$(date +%Y%m%d_%H%M%S).txt"
echo ""

# 배터리 전원 사용 시 최적화 설정
echo "⚡ 배터리 전원 사용 시 설정 최적화 중..."

# Power Nap 비활성화 (잠자기 중 백그라운드 활동 방지)
sudo pmset -b powernap 0
echo "  ✓ Power Nap 비활성화"

# Standby 모드 활성화 (일정 시간 후 deep sleep 진입)
sudo pmset -b standby 1
echo "  ✓ Standby 모드 활성화"

# Standby delay 설정 (30분 후 deep sleep 진입)
sudo pmset -b standbydelay 1800
echo "  ✓ Standby delay: 30분 (빠른 깨어남 → 배터리 절약 자동 전환)"

# 배터리 잔량 기준 설정 (50% 이상일 때만 standby 대기)
sudo pmset -b highstandbythreshold 50
echo "  ✓ High standby threshold: 50%"

# hibernatemode 설정
# 0 = 일반 sleep (RAM만 사용, 빠르지만 배터리 소모)
# 3 = safe sleep (RAM + Disk, 안전하지만 느림)
# 25 = hibernation (Disk만 사용, 배터리 소모 최소)
# Mode 3 + Standby: 처음엔 빠른 깨어남, 시간 경과 후 배터리 절약
sudo pmset -b hibernatemode 3
echo "  ✓ Hibernate mode: 3 (RAM + Disk 백업)"

# TCP Keep Alive 비활성화 (네트워크 연결 유지 방지)
sudo pmset -b tcpkeepalive 0
echo "  ✓ TCP Keep Alive 비활성화"

# 디스크 슬립 시간 단축
sudo pmset -b disksleep 10
echo "  ✓ 디스크 슬립: 10분"

# proximitywake 비활성화 (근접 기기로 인한 깨어남 방지)
sudo pmset -b proximitywake 0
echo "  ✓ Proximity Wake 비활성화"

echo ""
echo "🔌 AC 전원 사용 시 설정..."

# AC 전원 사용 시는 성능 우선
sudo pmset -c powernap 1
sudo pmset -c hibernatemode 3
sudo pmset -c tcpkeepalive 1
echo "  ✓ AC 전원: 성능 우선 설정 적용"

echo ""
echo "🎯 추가 최적화..."

# Bluetooth 깨어남 방지
sudo pmset -b ttyskeepawake 0
echo "  ✓ TTY Keep Awake 비활성화"

# 깨어남 요청 로그 활성화 (디버깅용)
sudo pmset -g log | grep -i wake > ~/wake_log_$(date +%Y%m%d_%H%M%S).txt 2>/dev/null || true
echo "  ✓ Wake 로그 저장"

echo ""
echo "✨ 최적화 완료!"
echo ""
echo "📊 현재 설정 확인:"
pmset -g

echo ""
echo "⚠️  참고사항:"
echo "  - 잠자기 후 30분까지: 빠른 깨어남 (1-3초)"
echo "  - 잠자기 후 30분 이후: 배터리 절약 모드 자동 진입 (깨어남 5-15초)"
echo "  - 배터리 50% 미만 시: 즉시 deep sleep 진입"
echo "  - 설정을 기본값으로 되돌리려면 restore-default-power-settings.sh를 실행하세요"
echo ""
