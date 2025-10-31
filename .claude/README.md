# Claude Code Statusline Configuration

이 디렉터리는 Claude Code의 커스텀 statusline 설정 파일들의 백업입니다.

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
- Claude Code가 다양한 작업 디렉터리에서 실행되기 때문에 상대 경로는 작동하지 않습니다
- 스크립트 내부에서 `~/.claude/projects/` 경로를 직접 참조합니다

실제 사용 위치: `~/.claude/` (홈 디렉터리)

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
- **Directory**: 현재 작업 디렉터리 (basename)

예시:
```
Ctx: 54.7k/200k (27%) | S: 114.4k/2.5M (5%) | W: 408.7k/30M (1%) | C: $0.30 | Sonnet 4.5 (default) | my-laptop
```

## 알려진 제한사항

### Claude Code Usage 제한 (확인된 사실)

**Anthropic이 공개한 정보:**
- **Max 5x 플랜**: Sonnet 4로 주당 140~280시간 사용 가능
- **두 가지 제한**: 5시간 세션 + 주간 제한이 동시에 적용됨
- **확인 방법**: `/usage` 명령으로 퍼센트만 확인 가능
- **비공개 정보**: 정확한 토큰 한도는 Anthropic이 공개하지 않음

**이 스크립트의 제약:**
- 정확한 토큰 한도를 알 수 없어 추정치 사용 중
- Session: 2.5M tokens (추정)
- Weekly: 30M tokens (추정)
- 실제 한도와 다를 수 있음

### Usage 계산의 부정확성

현재 구현에서는 모든 usage를 **근사치**로 계산합니다:

1. **Session (5시간 window)**
   - 추정 budget: 2.5M tokens
   - 실제 Anthropic의 정확한 session budget 한도를 알 수 없음
   - 5시간 동안의 모든 프로젝트 output token만 합산
   - ⚠️ **부정확**: 실제로는 input + output + cache 모두 계산해야 하나 output만 계산 중

2. **Weekly (7일 window)**
   - 추정 budget: 30M tokens
   - 실제 Anthropic의 정확한 weekly budget 한도를 알 수 없음
   - 7일 동안의 모든 프로젝트 output token만 합산
   - ⚠️ **부정확**: 실제로는 input + output + cache 모두 계산해야 하나 output만 계산 중

3. **Context (현재 대화)**
   - Input tokens (cache_read + cache_creation + input)만 합산
   - ⚠️ **부정확**: 실제로는 input + output 모두 계산해야 하나 input만 계산 중
   - 실제 사용량보다 **낮게** 표시됨

4. **왜 정확하지 않은가?**
   - **Session/Weekly**: Output만 계산 (input + cache 누락)
   - **Context**: Input만 계산 (output 누락)
   - **캐시 할인**: Cache read tokens는 10% 비용이지만 100%로 계산됨
   - **Budget 리셋 시간**: 정확한 리셋 시간을 알 수 없음
   - **API 제약**: `/usage` 명령은 interactive UI 전용이며 스크립트에서 실행 불가
   - **로컬 계산**: Transcript 파일 기반 계산이라 timezone/리셋 시간 불일치 가능

5. **정확한 usage를 보려면**
   - Claude Code에서 `/usage` 명령을 직접 실행하세요
   - 자동화된 정확한 표시는 현재 기술적으로 불가능

## 캐시 파일

다음 캐시 파일들이 자동 생성됩니다:
- `~/.claude/.statusline_cache` - Statusline 출력 캐시 (60초 TTL)
- `~/.claude/.context_tokens_cache` - Context token 캐시
- `~/.claude/.statusline_input_debug.json` - 디버그용 JSON

## 참고

이 설정은 로컬 transcript 기반 근사 계산입니다:
- **Context**: Input tokens만 계산 (실제는 input + output 모두 필요)
- **Session/Weekly**: Output tokens만 계산 (실제는 input + output + cache 모두 필요)
- **캐시 할인율**: 반영되지 않음 (cache read = 10% 비용이지만 100%로 계산)
- **결과**: `/usage`의 정확한 값과 큰 차이가 있을 수 있습니다

완전 자동화된 정확한 usage 표시는 Claude Code 자체에서 API를 제공해야 가능합니다.
