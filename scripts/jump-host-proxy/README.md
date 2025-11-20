# AKS SSH Tunnel Manager

Azure Kubernetes Service (AKS) Private Cluster에 SSH 터널을 통해 접속하기 위한 스크립트입니다.

## 필수 파일 설정

### 1. SSH 키 파일 (.pem)
Bastion 호스트에 접속하기 위한 SSH 키 파일을 현재 디렉토리에 배치하세요.
- 파일 확장자: `.pem`
- 1개만 있으면 자동으로 선택됩니다
- 여러 개가 있으면 선택 메뉴가 표시됩니다

### 2. Bastion 정보 (bastion.info)
```bash
cp bastion.info.example bastion.info
```

`bastion.info` 파일을 생성하고 다음 정보를 입력하세요:
```bash
BASTION_USER="your-username"
BASTION_HOST="your-bastion-ip-or-hostname"
LOCAL_PORT="8443"  # 선택사항, 기본값: 8443
```

### 3. Kubernetes 설정 (kubeconfig)
AKS 클러스터의 kubeconfig 파일을 `kubeconfig` 이름으로 저장하세요.

**Azure Portal에서 다운로드:**
1. AKS 클러스터 → Overview → Connect
2. kubeconfig 다운로드
3. 현재 디렉토리에 `kubeconfig` 이름으로 저장

**또는 Azure CLI 사용:**
```bash
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --file ./kubeconfig
```

## 사용 방법

### 터널 시작
```bash
# 일반 실행
./start-tunnel.sh

# source로 실행 (KUBECONFIG 자동 설정)
source ./start-tunnel.sh
# 또는
. ./start-tunnel.sh
```

### 터널 종료
```bash
# 일반 실행
./stop-tunnel.sh

# source로 실행 (KUBECONFIG 자동 원복)
source ./stop-tunnel.sh
# 또는
. ./stop-tunnel.sh
```

### kubectl 사용
터널이 시작되면 kubectl 명령을 사용할 수 있습니다:
```bash
kubectl get nodes
kubectl get pods -A
```

## 주요 기능

- **자동 SSH 키 선택**: .pem 파일 자동 감지 및 선택
- **동적 kubeconfig 생성**: 원본 kubeconfig에서 로컬 접속용 설정 자동 생성
- **환경 변수 자동 설정**: source로 실행 시 KUBECONFIG 자동 설정/원복
- **터널 상태 관리**: 이중 실행 방지 및 PID 기반 프로세스 관리

## 파일 구조

```
.
├── start-tunnel.sh           # 터널 시작 스크립트
├── stop-tunnel.sh            # 터널 종료 스크립트
├── bastion.info.example      # Bastion 정보 예시 파일
├── bastion.info              # Bastion 정보 (gitignore)
├── kubeconfig                # AKS kubeconfig (gitignore)
├── kubeconfig-local          # 로컬 접속용 kubeconfig (자동 생성, gitignore)
├── tunnel.pid                # 터널 PID 파일 (자동 생성, gitignore)
└── *.pem                     # SSH 키 파일 (gitignore)
```

## 주의사항

- `.pem`, `bastion.info`, `kubeconfig` 파일은 민감한 정보를 포함하므로 Git에 커밋하지 마세요 (.gitignore에 포함됨)
- 터널을 종료하려면 반드시 `stop-tunnel.sh`를 사용하세요
- 터널이 실행 중인 상태에서 스크립트를 다시 실행하면 경고 메시지가 표시됩니다

## 문제 해결

### kubectl 연결 실패
터널은 생성되었으나 kubectl 연결이 실패하는 경우:
```bash
# 몇 초 대기 후 재시도
kubectl get nodes
```

### 터널이 응답하지 않는 경우
```bash
./stop-tunnel.sh
./start-tunnel.sh
```

### PID 파일 오류
```bash
rm -f tunnel.pid
./start-tunnel.sh
```
