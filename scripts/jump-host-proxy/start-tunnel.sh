#!/bin/bash

# SSH Tunnel 시작 스크립트
# source 또는 . 명령으로 실행하면 현재 셸에 KUBECONFIG가 자동 설정됩니다

# 스크립트가 source로 실행되었는지 확인
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=true
else
    SOURCED=false
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/tunnel.pid"
KUBECONFIG_SOURCE="$SCRIPT_DIR/kubeconfig"
KUBECONFIG_LOCAL="$SCRIPT_DIR/kubeconfig-local"
BASTION_INFO="$SCRIPT_DIR/bastion.info"

# bastion.info 파일 확인 및 로드
if [ ! -f "$BASTION_INFO" ]; then
    echo "❌ bastion.info 파일을 찾을 수 없습니다: $BASTION_INFO"
    echo ""
    echo "다음 형식으로 bastion.info 파일을 생성하세요:"
    echo ""
    echo "------- bastion.info -------"
    echo "BASTION_USER=\"your-username\""
    echo "BASTION_HOST=\"your-bastion-ip-or-hostname\""
    echo "LOCAL_PORT=\"8443\"  # 선택사항, 기본값: 8443"
    echo "----------------------------"
    echo ""
    echo "설명:"
    echo "  BASTION_USER: SSH 접속에 사용할 사용자 이름 (필수)"
    echo "  BASTION_HOST: Bastion 호스트의 IP 주소 또는 도메인 (필수)"
    echo "  LOCAL_PORT:   로컬 포워딩 포트 번호 (선택, 기본값: 8443)"
    echo ""
    echo "💡 TIP: bastion.info.example 파일을 복사하여 사용하세요"
    echo "  cp bastion.info.example bastion.info"
    echo ""
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi

# bastion.info 파일에서 설정 로드
source "$BASTION_INFO"

# 필수 변수 확인
if [ -z "$BASTION_USER" ] || [ -z "$BASTION_HOST" ]; then
    echo "❌ bastion.info 파일에 필수 정보가 누락되었습니다."
    echo ""
    echo "다음 변수가 모두 설정되어 있는지 확인하세요:"
    echo "  - BASTION_USER"
    echo "  - BASTION_HOST"
    echo ""
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi

# LOCAL_PORT 기본값 설정 (bastion.info에 없는 경우)
LOCAL_PORT="${LOCAL_PORT:-8443}"

# kubeconfig 파일 확인
if [ ! -f "$KUBECONFIG_SOURCE" ]; then
    echo "❌ kubeconfig 파일을 찾을 수 없습니다: $KUBECONFIG_SOURCE"
    echo ""
    echo "다음 중 하나를 수행하세요:"
    echo "  1. Azure Portal에서 kubeconfig를 다운로드하여 현재 디렉토리에 'kubeconfig' 이름으로 저장"
    echo "  2. az aks get-credentials 명령으로 kubeconfig를 생성한 후 현재 디렉토리에 복사"
    echo ""
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi

# kubeconfig에서 REMOTE_ENDPOINT 추출
REMOTE_ENDPOINT=$(sed -n 's/.*server: https:\/\/\([^:]*\).*/\1/p' "$KUBECONFIG_SOURCE" | head -1)
if [ -z "$REMOTE_ENDPOINT" ]; then
    echo "❌ kubeconfig에서 서버 엔드포인트를 찾을 수 없습니다."
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi

# kubeconfig-local 동적 생성
echo "→ kubeconfig-local 파일 생성 중..."
python3 - "$KUBECONFIG_SOURCE" "$KUBECONFIG_LOCAL" "$LOCAL_PORT" <<'EOF'
import sys
import re

input_file = sys.argv[1]
output_file = sys.argv[2]
local_port = sys.argv[3]

with open(input_file, 'r') as f:
    content = f.read()

# server URL을 localhost로 변경
content = re.sub(
    r'server: https://[^:]+:\d+',
    f'server: https://127.0.0.1:{local_port}',
    content
)

# certificate-authority-data 라인 제거
content = re.sub(r'^\s*certificate-authority-data:.*\n', '', content, flags=re.MULTILINE)

# - cluster: 다음에 insecure-skip-tls-verify 추가
content = re.sub(
    r'^(- cluster:)\n',
    r'\1\n    insecure-skip-tls-verify: true\n',
    content,
    flags=re.MULTILINE
)

with open(output_file, 'w') as f:
    f.write(content)
EOF

if [ $? -ne 0 ] || [ ! -f "$KUBECONFIG_LOCAL" ] || [ ! -s "$KUBECONFIG_LOCAL" ]; then
    echo "❌ kubeconfig-local 파일 생성 실패"
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi
echo "✅ kubeconfig-local 파일 생성 완료"

# .pem 파일 자동 선택
PEM_FILES=("$SCRIPT_DIR"/*.pem)
PEM_COUNT=0
for file in "${PEM_FILES[@]}"; do
    if [ -f "$file" ]; then
        ((PEM_COUNT++))
    fi
done

if [ $PEM_COUNT -eq 0 ]; then
    echo "❌ .pem 파일을 찾을 수 없습니다."
    echo "현재 디렉토리에 SSH 키 파일(.pem)을 배치하세요."
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
elif [ $PEM_COUNT -eq 1 ]; then
    for file in "${PEM_FILES[@]}"; do
        if [ -f "$file" ]; then
            SSH_KEY="$file"
            echo "→ SSH 키 파일: $(basename "$SSH_KEY")"
            break
        fi
    done
else
    echo "현재 디렉토리에 여러 개의 .pem 파일이 있습니다:"
    echo ""
    i=1
    declare -a VALID_PEMS
    for file in "${PEM_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "  $i) $(basename "$file")"
            VALID_PEMS[$i]="$file"
            ((i++))
        fi
    done
    echo ""
    read -p "사용할 SSH 키 번호를 선택하세요 (1-$PEM_COUNT): " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $PEM_COUNT ]; then
        SSH_KEY="${VALID_PEMS[$choice]}"
        echo "→ 선택한 SSH 키: $(basename "$SSH_KEY")"
    else
        echo "❌ 잘못된 선택입니다."
        if [ "$SOURCED" = true ]; then
            return 1
        else
            exit 1
        fi
    fi
fi

echo "======================================"
echo "AKS SSH Tunnel 시작"
echo "======================================"

# 이미 실행 중인 터널이 있는지 확인
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️  터널이 이미 실행 중입니다 (PID: $OLD_PID)"
        echo "기존 터널을 종료하려면 ./stop-tunnel.sh를 실행하세요."
        if [ "$SOURCED" = true ]; then
            return 1
        else
            exit 1
        fi
    else
        # PID 파일은 있지만 프로세스가 없는 경우
        rm -f "$PID_FILE"
    fi
fi

# SSH 터널 백그라운드로 시작
echo "→ SSH 터널 생성 중..."
ssh -i "$SSH_KEY" \
    -L ${LOCAL_PORT}:${REMOTE_ENDPOINT}:443 \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -N -f \
    ${BASTION_USER}@${BASTION_HOST}

# SSH 프로세스 PID 찾기
sleep 2
SSH_PID=$(pgrep -f "ssh.*${LOCAL_PORT}:${REMOTE_ENDPOINT}:443")

if [ -z "$SSH_PID" ]; then
    echo "❌ SSH 터널 생성 실패"
    if [ "$SOURCED" = true ]; then
        return 1
    else
        exit 1
    fi
fi

echo "$SSH_PID" > "$PID_FILE"
echo "✅ SSH 터널 생성 완료 (PID: $SSH_PID)"

# kubeconfig 설정
export KUBECONFIG="$KUBECONFIG_LOCAL"
echo ""
echo "→ Kubernetes 클러스터 연결 테스트 중..."
sleep 3

# kubectl 명령 테스트
if kubectl get nodes 2>/dev/null; then
    echo ""
    echo "======================================"
    echo "✅ 터널 설정 완료!"
    echo "======================================"
    echo ""
    if [ "$SOURCED" = true ]; then
        echo "✅ KUBECONFIG가 현재 셸에 자동 설정되었습니다!"
        echo ""
        echo "사용 방법:"
        echo "  kubectl get nodes"
        echo "  kubectl get pods -A"
    else
        echo "사용 방법:"
        echo "  export KUBECONFIG=$KUBECONFIG_LOCAL"
        echo "  kubectl get nodes"
        echo "  kubectl get pods -A"
        echo ""
        echo "💡 TIP: 'source ./start-tunnel.sh' 로 실행하면 KUBECONFIG가 자동 설정됩니다"
    fi
    echo ""
    echo "터널 종료:"
    echo "  ./stop-tunnel.sh"
    echo ""
else
    echo ""
    echo "⚠️  터널은 생성되었으나 kubectl 연결 실패"
    echo "몇 초 후 다시 시도해보세요:"
    if [ "$SOURCED" = true ]; then
        echo "  kubectl get nodes"
    else
        echo "  export KUBECONFIG=$KUBECONFIG_LOCAL"
        echo "  kubectl get nodes"
    fi
    echo ""
fi
