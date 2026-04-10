# Time Machine 설정 관리

Mac별 Time Machine 백업 설정을 기록하고, 공통 제외 경로를 관리합니다.

## 디렉터리 구조

```
timemachine/
├── common-exclusions.sh       # 모든 Mac 공통 제외 경로
└── machines/
    └── <hostname>/
        └── config.md          # Mac별 백업 디스크 및 설정 기록
```

## 새 Mac 셋업

```bash
# 1. 공통 제외 경로 적용
./common-exclusions.sh

# 2. machines/<hostname>/config.md 생성 및 기록
# 3. 백업 디스크 연결 후 시스템 설정 > Time Machine에서 디스크 선택
```

## Mac별 설정 현황

| hostname | 백업 디스크 | 상태 |
|----------|------------|------|
| intel-hoon | TimeMachine (/Volumes/TimeMachine, Samsung T7) | 설정 완료 |
| m2-hoon | TimeMachine (/Volumes/TimeMachine, Samsung T7) | 미확인 (M2에서 확인 필요) |
