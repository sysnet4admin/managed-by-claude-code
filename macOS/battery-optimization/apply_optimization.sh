#!/bin/bash

echo "🔋 macOS 배터리 최적화 설정 적용"
echo "================================"
echo ""

# 배터리 전원 사용 시 설정
echo "📱 배터리 전원 설정 최적화 중..."

# Power Nap 비활성화 (잠자기 중 백그라운드 활동 중지)
sudo pmset -b powernap 0

# Standby 활성화 및 설정 (Deep Sleep)
sudo pmset -b standby 1
sudo pmset -b standbydelay 1800  # 30분 후 Deep Sleep
sudo pmset -b highstandbythreshold 50  # 배터리 50% 이상일 때만 대기

# Hibernate Mode (RAM + Disk, Standby와 함께 사용)
sudo pmset -b hibernatemode 3

# TCP Keep Alive 비활성화 (네트워크로 인한 깨어남 방지)
sudo pmset -b tcpkeepalive 0

# Proximity Wake 비활성화 (근접 기기로 인한 깨어남 방지)
sudo pmset -b proximitywake 0

# TTY Keep Awake 비활성화
sudo pmset -b ttyskeepawake 0

# 디스플레이 슬립 시간
sudo pmset -b displaysleep 5

# 디스크 슬립 시간
sudo pmset -b disksleep 10

# 시스템 슬립 시간
sudo pmset -b sleep 15

echo ""
echo "✅ 배터리 최적화 완료!"
echo ""
echo "📊 변경된 설정:"
echo "  • Power Nap: OFF (백그라운드 활동 중지)"
echo "  • Standby: ON (30분 후 Deep Sleep)"
echo "  • Hibernate Mode: 3 (RAM + Disk)"
echo "  • TCP Keep Alive: OFF (네트워크 깨어남 방지)"
echo "  • Proximity Wake: OFF (근접 기기 깨어남 방지)"
echo "  • Display Sleep: 5분"
echo "  • Disk Sleep: 10분"
echo "  • System Sleep: 15분"
echo ""
echo "💡 현재 설정 확인:"
pmset -g custom
