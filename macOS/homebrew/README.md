# Homebrew 패키지 관리 도구

Homebrew에 설치된 패키지들의 정보를 분석하고 관리하는 도구입니다.

## 🎯 주요 기능

- 📊 설치된 모든 패키지의 정보를 한눈에 확인
- 📅 설치 일자 추적
- 💾 패키지별 용량 표시
- ⭐ 사용 빈도 자동 추정 (파일 접근 시간 기반)
- 🎖️ 중요도 자동 평가
- 🗑️ 제거 고려 대상 패키지 추천
- 📄 CSV 파일로 내보내기 (선택적)

## 🛠️ 제공 도구

### 1. 패키지 정보 분석 스크립트 (`brew_info.sh`)

설치된 모든 Homebrew 패키지의 상세 정보를 분석하고 표시합니다.

#### 기본 사용법

```bash
# 기본 분석 (터미널 출력만)
./brew_info.sh

# CSV 파일로 저장
./brew_info.sh --csv

# 도움말 보기
./brew_info.sh --help
```

#### 출력 정보

| 컬럼 | 설명 | 예시 |
|------|------|------|
| **패키지명** | Homebrew 패키지 이름 | git, python@3.12 |
| **설치일자** | 설치된 날짜 | 2025-01-13 |
| **용량** | 디스크 사용량 | 58M, 714M |
| **사용빈도** | 파일 접근 기반 추정 | ⭐⭐⭐ 매우 높음 ~ 거의 없음 |
| **중요도** | 자동 평가된 중요도 | 필수 ⭐⭐⭐, 높음 ⭐⭐, 낮음 |

#### 사용 빈도 기준

- **⭐⭐⭐ 매우 높음**: 1일 이내 사용
- **⭐⭐ 높음**: 1주일 이내 사용
- **⭐ 보통**: 1개월 이내 사용
- **낮음**: 3개월 이내 사용
- **거의 없음**: 3개월 이상 미사용

#### 중요도 기준

- **필수 ⭐⭐⭐**: git, python, curl, openssl 등 핵심 도구
- **높음 ⭐⭐**: awscli, gh, docker, tmux 등 개발/쉘 도구
- **보통**: 일반 도구
- **낮음**: 사용 빈도가 낮은 패키지
- **🔒 중요 의존성**: 시스템에 필요한 의존성 패키지

## 📊 사용 예시

### 1. 기본 분석

```bash
./brew_info.sh
```

**출력 예시:**
```
==============================================================================================================
패키지명                      설치일자            용량         사용빈도                 중요도
==============================================================================================================
git                       2025-01-13      58M        매우 높음 ⭐⭐⭐            필수 ⭐⭐⭐
azure-cli                 2025-01-13      714M       높음 ⭐⭐                높음 ⭐⭐
awscli                    2025-08-16      184M       높음 ⭐⭐                높음 ⭐⭐
qemu                      2025-01-13      670M       거의 없음                낮음
...

📊 통계:
  총 패키지: 82개
  직접 설치: 28개
  의존성: 54개

🗑️  제거 고려 대상 (낮은 중요도 + 낮은 사용빈도):
  - qemu                      용량: 670M     설치: 2025-01-13
  - podman                    용량: 74M      설치: 2024-05-28
  - k8sgpt                    용량: 87M      설치: 2024-06-29
```

### 2. CSV 파일 생성

```bash
./brew_info.sh --csv
```

CSV 파일이 생성됩니다:
- **위치**: `~/managed-by-claude-code/macOS/brew_packages.csv`
- **용도**: Excel, Numbers, Google Sheets에서 열어 추가 분석 가능

**CSV 예시:**
```csv
패키지명,설치일자,용량,사용빈도,중요도,직접설치
git,2025-01-13,58M,매우 높음 ⭐⭐⭐,필수 ⭐⭐⭐,True
azure-cli,2025-01-13,714M,높음 ⭐⭐,높음 ⭐⭐,True
qemu,2025-01-13,670M,거의 없음,낮음,True
```

## 🚀 빠른 시작

```bash
# 1. 저장소 클론 (최초 1회)
git clone https://github.com/sysnet4admin/managed-by-claude-code.git
cd managed-by-claude-code

# 2. 디렉토리 이동
cd macOS/homebrew

# 3. 패키지 분석
./brew_info.sh

# 4. 제거 고려 대상 확인
# 출력된 "제거 고려 대상" 섹션 참고

# 5. 필요시 패키지 제거
brew uninstall qemu podman k8sgpt

# 6. 정리
brew autoremove
brew cleanup -s
```

## 💡 활용 팁

### 1. 용량 큰 패키지 찾기

```bash
./brew_info.sh | grep -E "^\w+" | sort -k3 -hr | head -10
```

### 2. 최근 설치한 패키지 확인

```bash
./brew_info.sh | sort -k2 -r | head -20
```

### 3. 사용하지 않는 패키지 제거

스크립트가 추천하는 "제거 고려 대상"을 확인하고:

```bash
# 안전하게 하나씩 제거
brew uninstall 패키지명

# 의존성도 함께 제거
brew autoremove

# 캐시 정리
brew cleanup -s
```

### 4. 정기적인 관리

매월 또는 분기마다 실행하여:
- 사용하지 않는 패키지 확인
- 용량 큰 패키지 검토
- 업데이트 필요한 패키지 확인

```bash
# 패키지 분석
./brew_info.sh --csv

# 업데이트 가능한 패키지 확인
brew outdated

# 업데이트 실행
brew upgrade
```

## 🔍 기술 세부사항

### 사용 빈도 계산 방법

1. 패키지의 `bin` 디렉토리에 있는 실행 파일 확인
2. 파일의 최근 접근 시간(access time) 확인
3. 현재 시간과 비교하여 빈도 계산
4. bin 파일이 없으면 설치 후 경과 시간으로 추정

### 중요도 평가 기준

**자동 분류:**
- 핵심 도구: git, curl, python, openssl, ssh
- 개발 도구: gh, awscli, azure-cli, docker, kubernetes, terraform
- 쉘 도구: fish, tmux, vim, zsh, fzf, autojump
- 중요 의존성: ssl, python, ca-certificates 관련

**추가 고려사항:**
- 직접 설치 여부
- 사용 빈도 점수
- 패키지 이름 패턴 매칭

### 정렬 기준

1. **중요도** (높은 순)
2. **사용빈도** (높은 순)
3. **용량** (큰 순)

## 📋 요구사항

- macOS
- Homebrew 설치
- Python 3.x
- Bash shell

## 🔧 문제 해결

### Q: "Permission denied" 에러가 발생해요

**A:** 스크립트에 실행 권한을 부여하세요:
```bash
chmod +x brew_info.sh
```

### Q: 사용 빈도가 "확인 불가"로 표시돼요

**A:** 해당 패키지는 bin 파일이 없거나 라이브러리 의존성입니다. 정상입니다.

### Q: CSV 파일이 어디에 저장되나요?

**A:** `~/managed-by-claude-code/macOS/brew_packages.csv` 경로에 저장됩니다.

### Q: 특정 패키지의 중요도가 잘못 평가된 것 같아요

**A:** 스크립트 내의 `estimate_importance()` 함수를 수정하여 커스터마이징할 수 있습니다.

## 📖 관련 명령어

### Homebrew 기본 명령어

```bash
# 설치된 패키지 목록
brew list

# 패키지 정보 보기
brew info 패키지명

# 패키지 제거
brew uninstall 패키지명

# 사용하지 않는 의존성 제거
brew autoremove

# 캐시 정리
brew cleanup -s

# 업데이트 가능한 패키지 확인
brew outdated

# 모든 패키지 업데이트
brew upgrade

# 특정 패키지만 업데이트
brew upgrade 패키지명
```

### 직접 설치한 패키지만 보기

```bash
brew leaves
```

### 의존성 트리 보기

```bash
brew deps --tree 패키지명
```

## 📝 변경 이력

- **2025-10-28**: 초기 버전 생성
  - brew_info.sh 스크립트 추가
  - 5가지 정보 제공: 이름, 설치일자, 용량, 사용빈도, 중요도
  - CSV 내보내기 기능 (선택적)
  - 제거 추천 기능
  - 도움말 기능

---

**참고**: 이 도구는 정보 제공 목적이며, 실제 패키지 제거는 신중하게 진행하세요.
