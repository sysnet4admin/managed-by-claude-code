#!/bin/bash

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <URL> [INTERVAL]"
    echo ""
    echo "Arguments:"
    echo "  URL       Target URL to monitor (required, e.g., http://1.1.1.1)"
    echo "  INTERVAL  Check interval in seconds (optional, default: 1)"
    echo ""
    echo "Example:"
    echo "  $0 http://1.1.1.1"
    echo "  $0 http://1.1.1.1 5"
    exit 1
fi

URL="$1"
INTERVAL="${2:-1}"

echo "Monitoring: $URL (every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

previous_state=""
previous_url=""
fail_start=""

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL" 2>/dev/null); then
        if [ "$response" = "200" ]; then
            current_state="UP"
            status="✓ OK (HTTP $response)"
        else
            current_state="DOWN"
            status="✗ FAIL (HTTP $response)"
        fi
    else
        current_state="DOWN"
        status="✗ FAIL (No response)"
    fi

    # 응답 바디에서 서버 정보 추출
    response_body=$(curl -s -L "$URL" 2>/dev/null)

    # Server name (Pod 이름) 추출
    server_name=$(echo "$response_body" | grep -oE 'Server name:</span>[^<]*<span>[^<]+' | sed -E 's/.*<span>([^<]+).*/\1/' | xargs)

    # Server address (내부 IP:포트) 추출
    server_address=$(echo "$response_body" | grep -oE 'Server address:</span>[^<]*<span>[^<]+' | sed -E 's/.*<span>([^<]+).*/\1/' | xargs)

    # 최종 표시할 정보 결정
    if [ -n "$server_name" ] && [ -n "$server_address" ]; then
        current_pod="$server_name"
        current_url="$server_name @ $server_address"
    else
        # 정보가 없으면 연결된 호스트만 표시
        current_pod=$(curl -s -v "$URL" 2>&1 | grep -i "^* Connected to" | tail -1 | sed -E 's/.*Connected to ([^ ]+) .*/\1/')
        current_url="$current_pod"
    fi

    # endpoint 변경 감지
    if [ -n "$previous_url" ] && [ "$previous_url" != "$current_url" ]; then
        echo "[$timestamp] ==================== ENDPOINT CHANGED ===================="
        echo "[$timestamp] Previous: $previous_url"
        echo "[$timestamp] Current:  $current_url"
    fi

    # 상태 변경 감지
    if [ -n "$previous_state" ] && [ "$previous_state" != "$current_state" ]; then
        if [ "$current_state" = "DOWN" ]; then
            echo "[$timestamp] ==================== DOWN DETECTED ===================="
            fail_start="$timestamp"
        else
            echo "[$timestamp] ==================== UP DETECTED ===================="
            if [ -n "$fail_start" ]; then
                echo "[$timestamp] Downtime: from $fail_start to $timestamp"
                fail_start=""
            fi
        fi
    fi

    echo "[$timestamp] $status - Pod: $current_pod"
    previous_state="$current_state"
    previous_url="$current_url"

    sleep "$INTERVAL"
done
