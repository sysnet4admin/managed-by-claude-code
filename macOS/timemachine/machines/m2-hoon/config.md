# m2-hoon - Time Machine 설정

## 상태

- [ ] Time Machine 설정 미확인 (M2에서 직접 확인 필요)

## 머신 정보

| 항목 | 내용 |
|------|------|
| 사용자 | hj |
| hostname | m2-hoon (추정) |

## 백업 대상 디스크

| 항목 | 내용 |
|------|------|
| 디스크 이름 | TimeMachine |
| 디스크 UUID | (M2에서 확인 필요) |
| 마운트 경로 | /Volumes/TimeMachine |
| 연결 방식 | Local (Samsung T7) |
| 설정일 | (M2에서 확인 필요) |

## 설정 방법

```bash
# 1. 공통 제외 경로 적용
cd macOS/timemachine
./common-exclusions.sh

# 2. T7 연결 후 백업 목적지 설정
sudo tmutil setdestination /Volumes/TimeMachine

# 3. 설정 확인
tmutil destinationinfo
```

## 추가 제외 경로 (이 Mac 전용)

없음

## 메모

- 2026-04-10: intel-hoon에서 확인한 T7 백업 기록 (`2026-04-10-081253.previous`로 존재)
- 백업이 `.previous`로 밀려있음 — intel-hoon 첫 백업 시 발생. M2에서 재백업 필요
- M2에서 직접 접속 후 나머지 정보 채울 것
