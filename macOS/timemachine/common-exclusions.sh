#!/bin/bash

# Time Machine 공통 제외 경로 설정
# 목적: 불필요한 대용량 디렉터리를 백업에서 제외하여 백업 속도 및 용량 최적화
# 사용법: sudo ./common-exclusions.sh

echo "Time Machine 공통 제외 경로 설정 중..."

exclude() {
    if [ -e "$1" ]; then
        tmutil addexclusion "$1"
        echo "  제외: $1"
    else
        echo "  건너뜀 (없음): $1"
    fi
}

# 개발 의존성 (재설치 가능)
exclude ~/node_modules
exclude ~/.npm
exclude ~/.yarn/cache
exclude ~/.pnpm-store

# 빌드 아티팩트
exclude ~/.gradle/caches
exclude ~/.m2/repository
exclude ~/Library/Caches

# 가상환경
exclude ~/.venv
exclude ~/miniforge3
exclude ~/miniconda3
exclude ~/anaconda3

# 컨테이너/VM (대용량)
exclude ~/.docker/volumes
exclude ~/.lima

# 기타
exclude ~/.Trash

echo ""
echo "완료."
