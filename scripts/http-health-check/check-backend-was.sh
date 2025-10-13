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

echo "Monitoring Backend WAS: $URL (every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

previous_state=""
previous_was=""
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

    # 실제 연결된 IP 추출 (WAS 구분의 핵심)
    connected_info=$(curl -s -v "$URL" 2>&1 | grep -i "^* Connected to" | tail -1)
    connected_ip=$(echo "$connected_info" | sed -E 's/.*\(([0-9.]+)\).*/\1/')
    connected_host=$(echo "$connected_info" | sed -E 's/.*Connected to ([^ ]+) .*/\1/')

    # 응답 바디에서 서버 정보 추출
    response_body=$(curl -s -L "$URL" 2>/dev/null)

    # Server name (Pod 이름) 추출
    server_name=$(echo "$response_body" | grep -oE 'Server name:</span>[^<]*<span>[^<]+' | sed -E 's/.*<span>([^<]+).*/\1/' | xargs)

    # Server address (내부 IP:포트) 추출
    server_address=$(echo "$response_body" | grep -oE 'Server address:</span>[^<]*<span>[^<]+' | sed -E 's/.*<span>([^<]+).*/\1/' | xargs)

    # WAS 구분을 위한 추가 정보 추출
    # X-Server-ID 헤더 또는 응답 본문에서 WAS ID 추출 시도
    was_id=$(curl -s -I "$URL" 2>/dev/null | grep -i "X-Server-ID" | sed -E 's/.*: (.+)/\1/' | tr -d '\r' | xargs)

    # 헤더에 정보가 없으면 본문에서 추출 시도
    if [ -z "$was_id" ]; then
        was_id=$(echo "$response_body" | grep -oE '(WAS|Instance|Backend)[-_]?ID[^<]*:[^<]*[^<]+' | sed -E 's/.*:([^<]+).*/\1/' | xargs)
    fi

    # 여전히 정보가 없으면 실제 연결된 IP로 WAS 구분
    if [ -z "$was_id" ] && [ -n "$connected_ip" ]; then
        was_id="WAS-${connected_ip##*.}"  # IP 마지막 옥텟 사용
    fi

    # 최종 표시할 정보 결정
    if [ -n "$server_name" ] && [ -n "$server_address" ]; then
        current_pod="$server_name"
        current_was="[${was_id}] $server_name @ $server_address (Connected: $connected_ip)"
    elif [ -n "$connected_ip" ]; then
        current_pod="$connected_host"
        current_was="[${was_id}] $connected_host @ $connected_ip"
    else
        current_pod="$connected_host"
        current_was="$connected_host"
    fi

    # WAS 변경 감지
    if [ -n "$previous_was" ] && [ "$previous_was" != "$current_was" ]; then
        echo "[$timestamp] ==================== WAS CHANGED ===================="
        echo "[$timestamp] Previous WAS: $previous_was"
        echo "[$timestamp] Current WAS:  $current_was"
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

    echo "[$timestamp] $status - WAS: $current_was"
    previous_state="$current_state"
    previous_was="$current_was"

    sleep "$INTERVAL"
done
