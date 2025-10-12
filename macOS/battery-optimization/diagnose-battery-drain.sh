#!/bin/bash

# macOS 잠자기 모드 배터리 소모 진단 스크립트

echo "🔍 macOS 배터리 소모 진단 도구"
echo "================================"
echo ""

# 배터리 상태 확인
echo "🔋 배터리 상태:"
pmset -g batt
echo ""

# 현재 전원 설정
echo "⚙️  현재 전원 설정:"
pmset -g
echo ""

# 활성 Assertion 확인 (잠자기 방해 요소)
echo "⚠️  잠자기 방해 요소 (Active Assertions):"
pmset -g assertions | head -30
echo ""

# 최근 깨어남 원인 분석
echo "🌅 최근 깨어남 원인 (Wake Reasons):"
echo "최근 10개 이벤트:"
pmset -g log | grep -i "wake reason" | tail -10 || echo "  (로그 없음)"
echo ""

# DarkWake 이벤트 확인
echo "🌙 DarkWake 이벤트 (백그라운드 깨어남):"
pmset -g log | grep -i "darkwake" | tail -5 || echo "  (이벤트 없음)"
echo ""

# 배터리 소모 과다 프로세스
echo "🔥 CPU 사용량 상위 프로세스:"
ps aux | sort -rk 3,3 | head -6
echo ""

# 네트워크 활동
echo "🌐 네트워크 연결 상태:"
netstat -an | grep ESTABLISHED | wc -l | xargs echo "  활성 연결 수:"
echo ""

# Bluetooth 장치
echo "📡 Bluetooth 장치:"
system_profiler SPBluetoothDataType 2>/dev/null | grep -i "connected: yes" -B 2 || echo "  (연결된 장치 없음)"
echo ""

# 진단 결과 저장
REPORT_FILE=~/battery_drain_report_$(date +%Y%m%d_%H%M%S).txt
echo "💾 상세 리포트 저장 중: $REPORT_FILE"

{
    echo "=== macOS 배터리 소모 진단 리포트 ==="
    echo "생성 시간: $(date)"
    echo ""
    echo "=== 배터리 상태 ==="
    pmset -g batt
    echo ""
    echo "=== 전원 설정 ==="
    pmset -g
    echo ""
    echo "=== Active Assertions ==="
    pmset -g assertions
    echo ""
    echo "=== 최근 20개 Wake Reasons ==="
    pmset -g log | grep -i "wake reason" | tail -20
    echo ""
    echo "=== DarkWake 이벤트 ==="
    pmset -g log | grep -i "darkwake" | tail -20
    echo ""
    echo "=== Sleep/Wake 통계 ==="
    pmset -g log | grep -E "Sleep|Wake" | tail -30
    echo ""
    echo "=== CPU 사용량 상위 프로세스 ==="
    ps aux | sort -rk 3,3 | head -11
    echo ""
    echo "=== 메모리 사용량 상위 프로세스 ==="
    ps aux | sort -rk 4,4 | head -11
    echo ""
} > "$REPORT_FILE"

echo "✅ 리포트 저장 완료!"
echo ""

# 권장사항
echo "📝 권장 조치사항:"
echo ""

# Power Nap 확인
if pmset -g | grep -q "powernap.*1"; then
    echo "  ⚠️  Power Nap이 활성화되어 있습니다"
    echo "      → 비활성화 권장: sudo pmset -b powernap 0"
    echo ""
fi

# hibernatemode 확인
HIBERNATE_MODE=$(pmset -g | grep hibernatemode | awk '{print $2}')
if [ "$HIBERNATE_MODE" != "25" ]; then
    echo "  💡 Hibernate mode가 $HIBERNATE_MODE 입니다"
    echo "      → 배터리 절약을 위해 25로 변경 권장: sudo pmset -b hibernatemode 25"
    echo "      (주의: 잠자기 진입/해제 시간이 늘어날 수 있음)"
    echo ""
fi

# TCP Keep Alive 확인
if pmset -g | grep -q "tcpkeepalive.*1"; then
    echo "  ⚠️  TCP Keep Alive가 활성화되어 있습니다"
    echo "      → 비활성화 권장: sudo pmset -b tcpkeepalive 0"
    echo ""
fi

echo "🚀 빠른 최적화:"
echo "  ./optimize-sleep-battery.sh 스크립트를 실행하여 자동 최적화하세요"
echo ""
