#!/bin/bash

# SSH Tunnel 종료 스크립트
# source 또는 . 명령으로 실행하면 현재 셸의 KUBECONFIG가 자동으로 원복됩니다

# 스크립트가 source로 실행되었는지 확인
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=true
else
    SOURCED=false
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/tunnel.pid"

echo "======================================"
echo "AKS SSH Tunnel 종료"
echo "======================================"

# PID 파일 확인
if [ ! -f "$PID_FILE" ]; then
    echo "⚠️  실행 중인 터널이 없습니다."
    echo "PID 파일을 찾을 수 없습니다: $PID_FILE"
    if [ "$SOURCED" = true ]; then
        return 0
    else
        exit 0
    fi
fi

# PID 읽기
SSH_PID=$(cat "$PID_FILE")

# 프로세스 확인 및 종료
if ps -p "$SSH_PID" > /dev/null 2>&1; then
    echo "→ SSH 터널 종료 중... (PID: $SSH_PID)"
    kill "$SSH_PID"

    # 종료 확인
    sleep 1
    if ps -p "$SSH_PID" > /dev/null 2>&1; then
        echo "⚠️  정상 종료 실패, 강제 종료 시도..."
        kill -9 "$SSH_PID"
        sleep 1
    fi

    if ps -p "$SSH_PID" > /dev/null 2>&1; then
        echo "❌ 프로세스 종료 실패"
        if [ "$SOURCED" = true ]; then
            return 1
        else
            exit 1
        fi
    else
        echo "✅ SSH 터널 종료 완료"
    fi
else
    echo "⚠️  PID $SSH_PID 프로세스가 실행 중이 아닙니다."
fi

# PID 파일 삭제
rm -f "$PID_FILE"
echo "✅ PID 파일 삭제 완료"

# KUBECONFIG 환경 변수 원복
if [ "$SOURCED" = true ]; then
    unset KUBECONFIG
    echo "✅ KUBECONFIG 환경 변수 원복 완료"
fi

echo ""
echo "======================================"
echo "정리 완료"
echo "======================================"
echo ""

if [ "$SOURCED" = true ]; then
    echo "✅ KUBECONFIG가 자동으로 원복되었습니다!"
else
    echo "KUBECONFIG 환경 변수를 수동으로 원복하세요:"
    echo "  unset KUBECONFIG"
    echo ""
    echo "💡 TIP: 'source ./stop-tunnel.sh' 로 실행하면 KUBECONFIG가 자동 원복됩니다"
fi
echo ""
