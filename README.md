# Managed by Claude Code

Claude를 활용하여 작성한 macOS 및 시스템 관리 스크립트 모음입니다.

## 📁 프로젝트 구조

```
managed-by-claude-code/
├── .claude/                      # Claude Code 설정
│   ├── statusline-command.sh     # Statusline 표시 스크립트
│   ├── update-context-cache.sh   # Context 캐시 업데이트 hook
│   └── commands/                 # 커스텀 명령어
├── macOS/
│   ├── battery-optimization/    # 배터리 최적화 도구
│   └── homebrew/                 # Homebrew 패키지 관리 도구
└── scripts/
    ├── http-health-check/        # HTTP 헬스체크 도구
    └── jump-host-proxy/          # AKS SSH 터널 관리 도구
```

## 🛠️ 도구 목록

### Claude Code 설정

#### [Statusline Configuration](.claude/)
Claude Code의 커스텀 statusline 설정

**주요 기능:**
- Context window, Session, Weekly usage 실시간 표시
- Token 기반 사용량 계산
- PostToolUse hook으로 자동 업데이트
- `/refresh` 커맨드 지원

### macOS

#### 1. [배터리 최적화](macOS/battery-optimization/)
잠자기 모드에서 배터리 소모를 최소화하는 도구 모음

**주요 기능:**
- 배터리 소모 원인 진단
- 전원 설정 자동 최적화
- 기본 설정 복원

**예상 효과:**
- 8시간 잠자기 후 배터리 손실: 8-15% → 1-4%
- 대기 시간: 3-5일 → 1-2주

#### 2. [Homebrew 패키지 관리](macOS/homebrew/)
Homebrew 패키지 정보를 분석하고 관리하는 도구

**주요 기능:**
- 패키지명, 설치일자, 용량, 사용빈도, 중요도 분석
- 제거 고려 대상 추천
- CSV 파일 내보내기

**활용:**
- 디스크 공간 확보
- 사용하지 않는 패키지 정리
- 패키지 사용 현황 추적

### Scripts

#### 1. [HTTP Health Check](scripts/http-health-check/)
HTTP 엔드포인트 상태를 모니터링하는 도구

#### 2. [AKS SSH Tunnel Manager](scripts/jump-host-proxy/)
Azure Kubernetes Service (AKS) Private Cluster에 SSH 터널을 통해 접속하는 도구

**주요 기능:**
- Bastion 호스트를 통한 자동 SSH 터널 생성
- 동적 kubeconfig 생성 (localhost 포워딩)
- SSH 키 자동 선택 및 관리
- 터널 상태 관리 (PID 기반)
- source 실행 시 KUBECONFIG 자동 설정/원복

**활용:**
- Private AKS 클러스터 로컬 접근
- kubectl 명령 실행
- 개발 환경에서 안전한 클러스터 관리

## 🚀 빠른 시작

### 저장소 클론
```bash
git clone https://github.com/sysnet4admin/managed-by-claude-code.git
cd managed-by-claude-code
```

### 배터리 최적화
```bash
cd macOS/battery-optimization
./diagnose-battery-drain.sh          # 진단
sudo ./optimize-sleep-battery.sh     # 최적화 적용
```

### Homebrew 패키지 관리
```bash
cd macOS/homebrew
./brew_info.sh                       # 패키지 분석
./brew_info.sh --csv                 # CSV로 저장
```

### HTTP Health Check
```bash
cd scripts/http-health-check
./check-response.sh https://example.com
```

### AKS SSH Tunnel Manager
```bash
cd scripts/jump-host-proxy
# 설정 파일 생성
cp bastion.info.example bastion.info
# bastion.info 편집 (사용자 정보, 호스트 정보 입력)
# kubeconfig 파일 배치
# .pem SSH 키 배치

# 터널 시작 (KUBECONFIG 자동 설정)
source ./start-tunnel.sh

# kubectl 사용
kubectl get nodes

# 터널 종료 (KUBECONFIG 자동 원복)
source ./stop-tunnel.sh
```

## 📋 요구사항

- macOS (Big Sur 이상 권장)
- Bash shell
- Homebrew (homebrew 도구 사용 시)
- Python 3.x (일부 스크립트)
- kubectl (AKS SSH Tunnel Manager 사용 시)

## 💡 사용 팁

1. **정기적인 실행**: 월 1회 정도 각 도구를 실행하여 시스템 상태 확인
2. **백업**: 시스템 설정 변경 전 자동 백업 파일 확인
3. **로그 확인**: 각 도구의 출력 로그를 저장하여 변화 추적

## 🔐 안전 수칙

- 시스템 설정을 변경하는 스크립트는 `sudo` 권한이 필요합니다
- 실행 전 자동 백업이 생성되지만, 중요한 작업 전에는 수동 백업 권장
- 각 도구의 README를 먼저 읽어보세요

## 📝 변경 이력

### 2025-11-20
- AKS SSH Tunnel Manager 추가
- Private AKS 클러스터 접근을 위한 SSH 터널 자동화 도구
- 메인 README에 jump-host-proxy 섹션 추가

### 2025-10-31
- Claude Code Statusline 설정 추가
- 메인 README에 Claude Code 설정 섹션 추가

### 2025-10-28
- Homebrew 패키지 관리 도구 추가
- 메인 README 생성

### 2025-10-07
- 배터리 최적화 도구 추가
- HTTP Health Check 도구 추가

---

**Made with ❤️ by Claude Code**

> 개인 사용 목적의 스크립트 모음입니다.
