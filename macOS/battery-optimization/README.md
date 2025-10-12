# macOS 잠자기 모드 배터리 최적화 가이드

macOS의 잠자기 모드에서 배터리 소모를 최소화하기 위한 도구 모음입니다.

## 🔍 문제 원인

macOS의 잠자기 모드에서 배터리가 과도하게 소모되는 주요 원인:

1. **Power Nap** - 잠자기 중에도 백그라운드 작업 수행
2. **네트워크 연결 유지** - TCP Keep Alive로 인한 지속적인 깨어남
3. **Hibernate Mode 설정** - RAM에 계속 전력 공급
4. **백그라운드 프로세스** - 잠자기를 방해하는 앱들
5. **Bluetooth/WiFi 장치** - 연결된 기기로 인한 깨어남

## 📋 현재 시스템 분석 결과

귀하의 시스템에서 발견된 주요 설정:

- **powernap**: 1 (활성화) ⚠️ - 잠자기 중 백그라운드 활동
- **hibernatemode**: 3 - RAM + Disk (배터리 소모 중간)
- **tcpkeepalive**: 1 (활성화) ⚠️ - 네트워크 연결 유지
- **standby**: 1 (활성화) ✓

## 🛠️ 제공 도구

### 1. 진단 스크립트 (`diagnose-battery-drain.sh`)

현재 배터리 소모 원인을 분석합니다.

```bash
chmod +x diagnose-battery-drain.sh
./diagnose-battery-drain.sh
```

**출력 정보:**
- 배터리 상태 및 현재 전원 설정
- 잠자기를 방해하는 프로세스/서비스
- 최근 깨어남 원인 (Wake Reasons)
- DarkWake 이벤트 (백그라운드 깨어남)
- CPU/메모리 사용량 상위 프로세스
- 상세 리포트 파일 생성 (`~/battery_drain_report_*.txt`)

### 2. 최적화 스크립트 (`optimize-sleep-battery.sh`)

배터리 절약을 위한 최적 설정을 자동으로 적용합니다.

```bash
chmod +x optimize-sleep-battery.sh
sudo ./optimize-sleep-battery.sh
```

**적용되는 설정 (배터리 전원 시):**

| 설정 | 변경 전 | 변경 후 | 효과 |
|------|---------|---------|------|
| powernap | 1 (ON) | 0 (OFF) | 백그라운드 활동 중지 |
| hibernatemode | 3 | 25 | RAM 전력 차단, Disk만 사용 |
| tcpkeepalive | 1 (ON) | 0 (OFF) | 네트워크 깨어남 방지 |
| proximitywake | 1 (ON) | 0 (OFF) | 근접 기기 깨어남 방지 |
| ttyskeepawake | 1 (ON) | 0 (OFF) | 직렬 포트 깨어남 방지 |
| standbydelay | - | 10800초 | 3시간 후 deep sleep |

**주의사항:**
- `hibernatemode 25`는 잠자기 진입/해제 시간이 3-10초 정도 늘어날 수 있습니다
- AC 전원 사용 시는 성능 우선 설정이 유지됩니다
- 실행 전 현재 설정이 자동으로 백업됩니다 (`~/macos_power_settings_backup_*.txt`)

### 3. 복원 스크립트 (`restore-default-power-settings.sh`)

설정을 macOS 기본값으로 되돌립니다.

```bash
chmod +x restore-default-power-settings.sh
sudo ./restore-default-power-settings.sh
```

## 📊 예상 효과

최적화 적용 후:

- **잠자기 중 배터리 소모**: 시간당 1-2% → **0.1-0.5%**
- **8시간 잠자기 후 배터리 손실**: 8-15% → **1-4%**
- **대기 시간**: 3-5일 → **1-2주**

*실제 효과는 사용 환경에 따라 다를 수 있습니다*

## 🚀 빠른 시작

```bash
# 1. 먼저 진단 실행
./diagnose-battery-drain.sh

# 2. 리포트 확인
cat ~/battery_drain_report_*.txt

# 3. 최적화 적용
sudo ./optimize-sleep-battery.sh

# 4. 하루 정도 사용 후 배터리 소모 확인
# 필요시 설정 복원
sudo ./restore-default-power-settings.sh
```

## 💡 추가 팁

### 1. Bluetooth 및 WiFi 관리
잠자기 전 불필요한 연결 해제:
```bash
# Bluetooth 끄기
sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0

# WiFi 끄기 (필요시)
networksetup -setairportpower en0 off
```

### 2. 백그라운드 앱 확인
잠자기를 방해하는 앱 확인:
```bash
pmset -g assertions
```

자주 발견되는 앱:
- Chrome/Safari (열린 탭이 많을 때)
- Spotify, Music (재생 중)
- 클라우드 동기화 앱 (Dropbox, OneDrive)
- 메신저 앱

### 3. 수동 설정 조정

더 공격적인 배터리 절약이 필요한 경우:
```bash
# 디스크 슬립을 더 빠르게
sudo pmset -b disksleep 5

# Standby를 더 빠르게 (1시간 후)
sudo pmset -b standbydelay 3600
```

빠른 재개가 중요한 경우:
```bash
# hibernatemode를 3으로 (RAM + Disk)
sudo pmset -b hibernatemode 3
```

### 4. 특정 앱의 백그라운드 활동 제한

**시스템 설정 > 배터리 > 배터리 사용 기록**에서:
- 백그라운드 활동이 많은 앱 확인
- "백그라운드 앱 새로 고침" 끄기

## 🔧 문제 해결

### Q: 최적화 후 잠자기 해제가 느려졌어요
**A:** `hibernatemode 25`가 원인입니다. 다음 명령으로 변경:
```bash
sudo pmset -b hibernatemode 3
```

### Q: 여전히 배터리가 많이 소모돼요
**A:** 진단 스크립트를 다시 실행하여 Wake Reason을 확인:
```bash
./diagnose-battery-drain.sh
pmset -g log | grep "wake reason" | tail -20
```

### Q: 특정 앱이 계속 깨어남을 유발해요
**A:** 해당 앱을 종료하거나 백그라운드 활동을 제한하세요.

### Q: 설정을 원래대로 되돌리고 싶어요
**A:** 복원 스크립트 실행:
```bash
sudo ./restore-default-power-settings.sh
```

## 📖 참고 자료

### pmset 주요 옵션

- `displaysleep` - 디스플레이 꺼짐 시간 (분)
- `sleep` - 시스템 잠자기 시간 (분, 0=끄기)
- `disksleep` - 하드 디스크 잠자기 시간 (분)
- `womp` - Wake on LAN (1=ON, 0=OFF)
- `ring` - Wake on modem ring (1=ON, 0=OFF)
- `powernap` - Power Nap (1=ON, 0=OFF)
- `proximitywake` - 근접 기기 깨어남 (1=ON, 0=OFF)
- `standby` - Standby 모드 (1=ON, 0=OFF)
- `standbydelay` - Standby 진입 시간 (초)
- `hibernatemode` - 0(RAM만), 3(RAM+Disk), 25(Disk만)
- `tcpkeepalive` - TCP 연결 유지 (1=ON, 0=OFF)

### 배터리 플래그
- `-b` - 배터리 전원 사용 시
- `-c` - AC 전원 사용 시
- `-a` - 모든 전원 상태

## 📝 변경 이력

- **2025-10-07**: 초기 버전 생성
  - 진단, 최적화, 복원 스크립트 추가
  - 상세 가이드 문서 작성

## 📮 피드백

문제가 발생하거나 개선 사항이 있으면 이슈를 등록해주세요.

---

**면책 조항**: 이 스크립트들은 시스템 전원 설정을 변경합니다. 실행 전 현재 설정이 자동으로 백업되지만, 사용은 본인의 책임하에 진행해주세요.
