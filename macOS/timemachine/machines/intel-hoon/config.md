# intel-hoon - Time Machine 설정

## 상태

- [x] Time Machine 설정 완료

## 백업 대상 디스크

| 항목 | 내용 |
|------|------|
| 디스크 이름 | TimeMachine |
| 디스크 UUID | E7583394-FA4E-4D66-B17B-9176ABCF8971 |
| 마운트 경로 | /Volumes/TimeMachine |
| 연결 방식 | Local |
| 설정일 | 2026-04-11 |

## 머신 정보

| 항목 | 내용 |
|------|------|
| 사용자 | hj |
| hostname | hoon-intelui-MacBookPro |

## 설정 방법

```bash
# 1. 공통 제외 경로 적용
cd macOS/timemachine
./common-exclusions.sh

# 2. 백업 디스크 연결 후 Time Machine 시스템 설정에서 디스크 선택

# 3. 설정 확인
tmutil destinationinfo
```

## 추가 제외 경로 (이 Mac 전용)

없음

## 메모

- 2026-04-11: `sudo tmutil setdestination /Volumes/TimeMachine`으로 설정 완료
