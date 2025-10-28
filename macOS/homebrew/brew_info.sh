#!/bin/bash

# Homebrew 패키지 정보 분석 스크립트
# 이름 | 설치일자 | 용량 | 사용빈도 | 중요도

# 도움말 출력
show_help() {
    cat << 'HELP'
사용법: brew_info.sh [옵션]

Homebrew에 설치된 패키지들의 정보를 분석하고 표시합니다.

옵션:
    --csv           분석 결과를 CSV 파일로 저장합니다
                    파일 위치: ~/managed-by-claude-code/macOS/brew_packages.csv

    --help, -h      이 도움말을 표시합니다

출력 정보:
    - 패키지명      : Homebrew 패키지 이름
    - 설치일자      : 설치된 날짜 (YYYY-MM-DD)
    - 용량         : 디스크 사용량
    - 사용빈도      : 파일 접근 시간 기반 추정
                     ⭐⭐⭐ 매우 높음, ⭐⭐ 높음, ⭐ 보통
    - 중요도       : 패키지 중요도 자동 추정
                     필수 ⭐⭐⭐, 높음 ⭐⭐, 보통, 낮음, 🔒 중요 의존성

예제:
    ./brew_info.sh              # 기본 분석
    ./brew_info.sh --csv        # CSV 파일로 저장
    ./brew_info.sh --help       # 도움말 표시

HELP
    exit 0
}

# 옵션 파싱
SAVE_CSV=false

for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            ;;
        --csv)
            SAVE_CSV=true
            shift
            ;;
        *)
            echo "알 수 없는 옵션: $arg"
            echo "./brew_info.sh --help 를 실행하여 도움말을 확인하세요."
            exit 1
            ;;
    esac
done

echo "Homebrew 패키지 분석 중..."
echo ""

# 임시 파일에 JSON 저장
TEMP_JSON=$(mktemp)
brew info --json=v2 --installed > "$TEMP_JSON"

python3 << EOF
import json
import subprocess
import os
from datetime import datetime

# 파일에서 JSON 읽기
with open('$TEMP_JSON', 'r') as f:
    data = json.load(f)

# 용량 확인 함수
def get_package_size(package_name):
    try:
        cellar_path = subprocess.check_output(["brew", "--cellar"], text=True).strip()
        package_path = f"{cellar_path}/{package_name}"
        if os.path.exists(package_path):
            result = subprocess.check_output(["du", "-sh", package_path], text=True).strip()
            return result.split()[0]
        return "N/A"
    except:
        return "N/A"

# 사용 빈도 추정 (마지막 접근 시간 기반)
def get_usage_frequency(package_name, install_days):
    try:
        cellar_path = subprocess.check_output(["brew", "--cellar"], text=True).strip()
        package_path = f"{cellar_path}/{package_name}"

        if not os.path.exists(package_path):
            return "알 수 없음", 0

        # bin 파일들의 최근 접근 시간 확인
        bin_files = []
        for root, dirs, files in os.walk(package_path):
            if 'bin' in root:
                for file in files:
                    file_path = os.path.join(root, file)
                    if os.path.isfile(file_path) or os.path.islink(file_path):
                        bin_files.append(file_path)

        if bin_files:
            # 가장 최근 접근된 파일 찾기
            latest_access = max(os.stat(f).st_atime for f in bin_files[:5])
            days_since_access = (datetime.now().timestamp() - latest_access) / 86400

            if days_since_access < 1:
                return "매우 높음 ⭐⭐⭐", 5
            elif days_since_access < 7:
                return "높음 ⭐⭐", 4
            elif days_since_access < 30:
                return "보통 ⭐", 3
            elif days_since_access < 90:
                return "낮음", 2
            else:
                return "거의 없음", 1

        # bin 파일이 없으면 설치 후 기간으로 추정
        if install_days < 30:
            return "최근 설치", 3
        else:
            return "확인 불가", 1

    except Exception as e:
        return "확인 불가", 1

# 크기를 바이트로 변환 (정렬용)
def get_size_bytes(size_str):
    if size_str == "N/A":
        return 0
    try:
        multipliers = {'K': 1024, 'M': 1024**2, 'G': 1024**3}
        if size_str[-1] in multipliers:
            return float(size_str[:-1]) * multipliers[size_str[-1]]
        return float(size_str)
    except:
        return 0

# 중요도 추정
def estimate_importance(name, on_request, usage_score):
    # 핵심 도구
    critical = ['git', 'curl', 'python', 'node', 'openssl', 'ssh']
    # 개발 도구
    dev_tools = ['gh', 'awscli', 'azure-cli', 'docker', 'kubernetes', 'terraform']
    # 쉘/터미널
    shell_tools = ['fish', 'tmux', 'vim', 'zsh', 'fzf', 'autojump']

    name_lower = name.lower()

    # 의존성 패키지
    if not on_request:
        # 중요한 의존성
        if any(c in name_lower for c in ['ssl', 'python', 'ca-cert']):
            return "중요 의존성 🔒", 4
        return "의존성", 1

    # 직접 설치한 패키지
    if any(c in name_lower for c in critical):
        return "필수 ⭐⭐⭐", 5
    elif any(d in name_lower for d in dev_tools):
        return "높음 ⭐⭐", 4
    elif any(s in name_lower for s in shell_tools):
        return "높음 ⭐⭐", 4
    elif usage_score >= 4:
        return "높음 (자주 사용)", 4
    elif usage_score >= 3:
        return "보통", 3
    else:
        return "낮음", 2

# 패키지 정보 수집
packages = []

for formula in data.get('formulae', []):
    name = formula['name']

    for install in formula.get('installed', []):
        install_time = install.get('time', 0)
        install_date = datetime.fromtimestamp(install_time)
        install_days = (datetime.now() - install_date).days
        on_request = install.get('installed_on_request', False)

        # 데이터 수집
        size = get_package_size(name)
        usage_freq, usage_score = get_usage_frequency(name, install_days)
        importance, importance_score = estimate_importance(name, on_request, usage_score)

        packages.append({
            'name': name,
            'date': install_date.strftime('%Y-%m-%d'),
            'size': size,
            'size_bytes': get_size_bytes(size),
            'usage': usage_freq,
            'usage_score': usage_score,
            'importance': importance,
            'importance_score': importance_score,
            'on_request': on_request
        })

# 정렬: 중요도 > 사용빈도 > 용량
packages.sort(key=lambda x: (-x['importance_score'], -x['usage_score'], -x['size_bytes']))

# 출력
print("=" * 110)
print(f"{'패키지명':<25} {'설치일자':<15} {'용량':<10} {'사용빈도':<20} {'중요도':<20}")
print("=" * 110)

for pkg in packages:
    name_display = pkg['name'][:24]
    print(f"{name_display:<25} {pkg['date']:<15} {pkg['size']:<10} {pkg['usage']:<20} {pkg['importance']:<20}")

print("=" * 110)
print()

# 통계
print("📊 통계:")
print(f"  총 패키지: {len(packages)}개")
print(f"  직접 설치: {sum(1 for p in packages if p['on_request'])}개")
print(f"  의존성: {sum(1 for p in packages if not p['on_request'])}개")
print()

# 제거 추천
print("🗑️  제거 고려 대상 (낮은 중요도 + 낮은 사용빈도):")
candidates = [p for p in packages if p['on_request'] and p['importance_score'] <= 2 and p['usage_score'] <= 2]
if candidates:
    for pkg in candidates[:5]:
        print(f"  - {pkg['name']:<25} 용량: {pkg['size']:<8} 설치: {pkg['date']}")
else:
    print("  없음")
print()

# CSV 저장 (옵션이 활성화된 경우만)
if '$SAVE_CSV' == 'true':
    csv_file = "/Users/hj/managed-by-claude-code/macOS/brew_packages.csv"
    print(f"📄 CSV 파일 생성 중: {csv_file}")

    with open(csv_file, 'w', encoding='utf-8') as f:
        f.write("패키지명,설치일자,용량,사용빈도,중요도,직접설치\n")
        for pkg in packages:
            f.write(f"{pkg['name']},{pkg['date']},{pkg['size']},{pkg['usage']},{pkg['importance']},{pkg['on_request']}\n")

    print(f"✅ CSV 파일이 저장되었습니다: {csv_file}")
    print()

EOF

# 임시 파일 삭제
rm -f "$TEMP_JSON"
