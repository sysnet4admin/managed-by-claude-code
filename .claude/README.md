# Claude Code Statusline Configuration

이 디렉토리는 Claude Code의 커스텀 statusline 설정 파일들의 백업입니다.

## 파일 목록

### 스크립트
- `statusline-command.sh` - Statusline 표시 로직 (context, session, weekly usage 계산)
- `update-context-cache.sh` - PostToolUse hook으로 실행되어 context token 캐시 업데이트

### 커맨드
- `commands/refresh.md` - `/refresh` 커맨드 정의

## 중요: 절대 경로 사용

**모든 스크립트는 절대 경로로 참조되어야 합니다.**

이유:
- `settings.json`의 `statusLine.command`와 `hooks`는 절대 경로가 필요합니다
- Claude Code가 다양한 작업 디렉토리에서 실행되기 때문에 상대 경로는 작동하지 않습니다
- 스크립트 내부에서 `~/.claude/projects/` 경로를 직접 참조합니다

실제 사용 위치: `~/.claude/` (홈 디렉토리)

## 설정 방법

`~/.claude/settings.json`에 다음과 같이 설정:

⚠️ **중요**: 아래 예시의 `/Users/YOUR_USERNAME/`을 본인의 실제 절대 경로로 변경해야 합니다.
- `$HOME`, `~` 등의 환경변수는 사용할 수 없습니다
- 반드시 전체 절대 경로를 입력하세요 (예: `/Users/your-actual-username/.claude/...`)

```json
{
  "statusLine": {
    "type": "command",
    "command": "/bin/bash /Users/YOUR_USERNAME/.claude/statusline-command.sh"
  },
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/bin/bash /Users/YOUR_USERNAME/.claude/update-context-cache.sh"
          }
        ]
      }
    ]
  }
}
```

## Statusline 표시 내용

- **Ctx**: Context window 사용량 (현재 대화의 token 수)
- **S**: Session 사용량 (5시간 윈도우)
- **W**: Weekly 사용량 (7일 윈도우)
- **C**: 비용 (현재 세션)
- **Model**: 현재 사용 중인 모델
- **디렉토리**: 현재 작업 디렉토리 (basename)

예시:
```
Ctx: 54.7k/200k (27%) | S: 114.4k/2.5M (5%) | W: 408.7k/30M (1%) | C: $0.30 | Sonnet 4.5 (default) | my-laptop
```

## 알려진 제한사항

### Session/Weekly Budget 계산의 부정확성

현재 구현에서는 Session과 Weekly usage를 **추정치**로 계산합니다:

1. **Session (5시간 window)**
   - 추정 budget: 2.5M tokens
   - 실제 Anthropic의 정확한 session budget 한도를 알 수 없음
   - 마지막 5시간 동안의 모든 프로젝트 output token을 합산

2. **Weekly (7일 window)**
   - 추정 budget: 30M tokens
   - 실제 Anthropic의 정확한 weekly budget 한도를 알 수 없음
   - 마지막 7일 동안의 모든 프로젝트 output token을 합산

3. **왜 정확하지 않은가?**
   - Claude Code의 `/usage` 명령은 interactive UI 전용이며 스크립트에서 실행 불가
   - Anthropic API에서 실시간 usage 데이터를 가져올 수 없음
   - Budget 리셋 시간이 정확히 언제인지 알 수 없음 (표시는 "Resets 7pm (Asia/Seoul)" 등)
   - 로컬 transcript 파일의 timestamp 기반 계산이라 timezone/리셋 시간 불일치 가능

4. **정확한 usage를 보려면**
   - Claude Code에서 `/usage` 명령을 직접 실행하세요
   - 자동화된 정확한 표시는 현재 기술적으로 불가능

### Context 계산은 정확함

- Context window 사용량은 정확합니다 (transcript에서 직접 읽음)
- Auto-compress 타이밍 예측 가능

## 캐시 파일

다음 캐시 파일들이 자동 생성됩니다:
- `~/.claude/.statusline_cache` - Statusline 출력 캐시 (60초 TTL)
- `~/.claude/.context_tokens_cache` - Context token 캐시
- `~/.claude/.statusline_input_debug.json` - 디버그용 JSON

## 참고

이 설정은 token 기반 계산으로, `/usage`의 정확한 퍼센트와 다를 수 있습니다.
완전 자동화된 정확한 usage 표시는 Claude Code 자체에서 API를 제공해야 가능합니다.
