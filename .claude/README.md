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

### 계산 방식 상세

#### 1. Context (현재 대화) - ✅ 정확
**계산 방식:**
- PostToolUse hook으로 매 도구 실행마다 자동 업데이트
- `cache_read_input_tokens + cache_creation_input_tokens + input_tokens`
- 가장 최근 assistant 메시지의 usage 데이터 사용

**정확도:**
- ✅ Claude Code가 보고하는 context window 사용량과 동일
- ✅ Auto-compress 시점 예측 가능 (200k 기준 22.5% 버퍼)

#### 2. Session (5시간 window) - ⚠️ 참고용 추정치
**계산 방식:**
- 5시간 동안의 모든 프로젝트에서 `output_tokens`만 합산
- 추정 budget: 2.5M tokens (실제 한도는 Anthropic 비공개)

**한계:**
- ⚠️ **Anthropic의 정확한 계산 방식을 알 수 없음** (output만? input+output? cache 가중치?)
- ⚠️ Output tokens만 계산하는 것으로 **추정**하여 구현
- ⚠️ 정확한 budget 한도를 알 수 없음 (2.5M은 역산한 추정치)
- ⚠️ Budget 리셋 시간 정확히 알 수 없음 (timezone 불일치 가능)

#### 3. Weekly (7일 window) - ⚠️ 참고용 추정치
**계산 방식:**
- 7일 동안의 모든 프로젝트에서 `output_tokens`만 합산
- 추정 budget: 30M tokens (실제 한도는 Anthropic 비공개)

**한계:**
- ⚠️ **Anthropic의 정확한 계산 방식을 알 수 없음** (output만? input+output? cache 가중치?)
- ⚠️ Output tokens만 계산하는 것으로 **추정**하여 구현
- ⚠️ 정확한 budget 한도를 알 수 없음 (30M은 역산한 추정치)
- ⚠️ Budget 리셋 시간 정확히 알 수 없음 (timezone 불일치 가능)

#### 정확한 usage 확인 방법
- **Claude Code에서 `/usage` 명령 실행** (이것만이 정확한 방법)
- Session/Weekly 사용량 퍼센트 확인 가능
- Statusline은 어디까지나 **참고용 추정치**일 뿐

## 캐시 파일

다음 캐시 파일들이 자동 생성됩니다:
- `~/.claude/.statusline_cache` - Statusline 출력 캐시 (60초 TTL)
- `~/.claude/.context_tokens_cache` - Context token 캐시
- `~/.claude/.statusline_input_debug.json` - 디버그용 JSON

## 참고

**이 statusline은 참고용 근사치입니다:**
- 로컬 transcript 파일 기반 계산으로 실제 usage와 차이가 있습니다
- 정확한 사용량은 `/usage` 명령으로 확인하세요
- 완전 자동화된 정확한 표시는 Claude Code에서 API를 제공해야 가능합니다

**용도:**
- Context window 사용량 모니터링 (auto-compress 시점 예측)
- Session/Weekly 사용 패턴 추적
- 대략적인 비용 추정
