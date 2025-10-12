#!/bin/bash

# macOS 전원 설정 기본값 복원 스크립트

set -e

echo "🔄 macOS 전원 설정 기본값으로 복원"
echo "====================================="
echo ""

# 배터리 전원 설정 복원
echo "⚡ 배터리 전원 설정 복원 중..."
sudo pmset -b powernap 1
sudo pmset -b standbydelay 10800
sudo pmset -b hibernatemode 3
sudo pmset -b tcpkeepalive 1
sudo pmset -b disksleep 10
sudo pmset -b proximitywake 1
sudo pmset -b ttyskeepawake 1

# AC 전원 설정 복원
echo "🔌 AC 전원 설정 복원 중..."
sudo pmset -c powernap 1
sudo pmset -c hibernatemode 3
sudo pmset -c tcpkeepalive 1

echo ""
echo "✅ 기본 설정으로 복원 완료!"
echo ""
echo "📊 현재 설정:"
pmset -g
echo ""
