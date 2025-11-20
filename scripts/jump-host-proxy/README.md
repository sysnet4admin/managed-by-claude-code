# Jump Host Proxy

Bastion/Jump Host를 통해 private 리소스에 SSH 터널로 접속하기 위한 범용 스크립트입니다.

**지원 환경:**
- Private Kubernetes 클러스터 (AKS, EKS, GKE 등)
- Private 데이터베이스 서버
- 내부 네트워크 서비스
- 기타 SSH 터널이 필요한 모든 private 리소스

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Local Development Environment                        │
│                                                                         │
│  ┌──────────────────┐                                                   │
│  │  Local Machine   │                                                   │
│  │  (127.0.0.1)     │                                                   │
│  │                  │                                                   │
│  │  kubectl ────────┼───► localhost:8443                                │
│  │                  │         │                                         │
│  │                  │         │ (kubeconfig-local)                      │
│  └──────────────────┘         │                                         │
│                                │                                        │
│         ┌──────────────────────┘                                        │
│         │  SSH Tunnel (Port Forwarding)                                 │
│         │  start-tunnel.sh                                              │
│         ▼                                                               │
└─────────────────────────────────────────────────────────────────────────┘
          │
          │ SSH Connection
          │ (ssh -L 8443:REMOTE_ENDPOINT:443)
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Public Network                                 │
│                                                                         │
│  ┌─────────────────────────────────────────────────────┐                │
│  │  Bastion / Jump Host                                 │               │
│  │  (Public IP)                                         │               │
│  │                                                       │              │
│  │  • SSH key-based authentication                      │               │
│  │  • Port forwarding relay                             │               │
│  │  • Security gateway                                  │               │
│  └─────────────────────────────────────────────────────┘                │
│                              │                                          │
└─────────────────────────────────────────────────────────────────────────┘
                               │
                               │ Private Network Access
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Private Network (VPC/VNet)                         │
│                                                                         │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐        │
│  │  AKS Cluster    │   │  EKS Cluster    │   │  GKE Cluster    │        │
│  │  (Private)      │   │  (Private)      │   │  (Private)      │        │
│  │                 │   │                 │   │                 │        │
│  │  API Server     │   │  API Server     │   │  API Server     │        │
│  │  (Private IP)   │   │  (Private IP)   │   │  (Private IP)   │        │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘        │
│                                                                         │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐        │
│  │  Database       │   │  Internal       │   │  Other          │        │
│  │  (Private)      │   │  Services       │   │  Resources      │        │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 동작 원리

1. **SSH 터널 생성**
   - 로컬 머신에서 Bastion Host로 SSH 연결
   - 로컬 포트(8443)를 원격 리소스(Private Kubernetes API Server)로 포워딩

2. **kubeconfig 변환** (Kubernetes 사용 시)
   - 원본 kubeconfig의 Private IP를 localhost:8443으로 변경
   - TLS 검증 우회 설정 추가 (insecure-skip-tls-verify)

3. **로컬 접근**
   - kubectl 명령이 localhost:8443으로 요청
   - SSH 터널이 자동으로 Bastion Host를 통해 Private 리소스로 전달

4. **투명한 프록시**
   - 사용자는 마치 로컬에서 직접 접근하는 것처럼 사용
   - 실제로는 SSH 터널을 통해 안전하게 접근

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

### 3. Kubernetes 설정 (kubeconfig) - 선택사항
Kubernetes 클러스터에 접근할 경우, kubeconfig 파일을 `kubeconfig` 이름으로 저장하세요.

**클라우드별 다운로드 방법:**

**Azure (AKS):**
```bash
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --file ./kubeconfig
```

**AWS (EKS):**
```bash
aws eks update-kubeconfig --name <cluster-name> --kubeconfig ./kubeconfig
```

**GCP (GKE):**
```bash
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>
# ~/.kube/config에서 ./kubeconfig로 복사
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
- **동적 kubeconfig 생성**: 원본 kubeconfig에서 로컬 접속용 설정 자동 생성 (Kubernetes 사용 시)
- **환경 변수 자동 설정**: source로 실행 시 KUBECONFIG 자동 설정/원복 (Kubernetes 사용 시)
- **터널 상태 관리**: 이중 실행 방지 및 PID 기반 프로세스 관리
- **범용성**: Kubernetes뿐만 아니라 모든 private 리소스 접근 가능

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
