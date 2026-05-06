# Claude Code Config

Global configuration files for consistent Claude Code settings across multiple machines.

여러 머신에서 동일한 Claude Code 글로벌 설정을 사용하기 위한 설정 파일입니다.

## Structure / 구조

```
claude-config/
├── .claude/
│   ├── settings.json         # Global settings / 글로벌 설정
│   ├── statusline-command.sh # Custom statusline / 커스텀 statusline
│   └── commands/             # Slash commands / 슬래시 명령어
│       ├── h.md              # /h - Haiku model
│       ├── o.md              # /o - Opus model
│       └── s.md              # /s - Sonnet model
├── sessions.zsh              # Session management functions / 세션 관리 함수
├── install.sh                # Installation script / 설치 스크립트
└── README.md
```

## Installation / 설치

```bash
cd claude-config
./install.sh
```

Creates symlinks in `~/.claude/`. Existing files are backed up as `.backup`.

`~/.claude/`에 symlink를 생성합니다. 기존 파일이 있으면 `.backup`으로 백업됩니다.

## Statusline Features / Statusline 기능

- Model name (Opus 4.5, Sonnet 4.5, etc.) / 모델명 표시
- Context usage gauge (green <50%, yellow 50-70%, red ≥70%) / 컨텍스트 사용량 게이지
- API usage (5-hour utilization + time until reset, from stdin JSON) / API 사용량 (5시간 사용률 + 리셋까지 남은 시간, stdin JSON 사용)
- Kubernetes context (if available) / Kubernetes 컨텍스트 (있는 경우)
- Current path (abbreviated) / 현재 경로 (축약형)

Example / 예시: `Opus 4.5 | ▓▓▓░░░░░░░ | 42% (Rst:3h24m) | my-cluster | project/.../src`

## Session Management / 세션 관리

`sessions.zsh` provides shell functions for resuming Claude Code sessions after unexpected termination.

`sessions.zsh`는 갑작스러운 종료 후 세션을 재개할 수 있는 zsh 함수를 제공합니다.

`install.sh` automatically adds the source line to `~/.zshrc`.

| Command | Description |
|---------|-------------|
| `claude-continue` | Resume the latest session in the current directory / 현재 디렉토리의 최근 세션 재개 |
| `claude-sessions` | List sessions with preview of first message / 세션 목록 + 첫 메시지 미리보기 |
| `claude-sessions <n>` | Resume session number n / n번 세션 재개 |

## After Changes / 설정 변경 후

Restart Claude Code to apply configuration changes.

설정 파일 수정 후 Claude Code를 재시작하면 적용됩니다.
