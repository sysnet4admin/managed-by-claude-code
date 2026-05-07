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
├── claude-history.zsh              # Session management functions / 세션 관리 함수
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

`claude-history.zsh` provides a shell function to browse all Claude Code sessions and resume the right one quickly.

`claude-history.zsh`는 전체 Claude Code 세션을 탐색하고 원하는 작업으로 빠르게 돌아갈 수 있는 zsh 함수를 제공합니다.

`install.sh` automatically adds the source line to `~/.zshrc`. Requires `fzf` (`brew install fzf`).

### `claude-history`

Opens an fzf TUI showing recent sessions with the **last input** as a preview. Selecting a session automatically `cd`s to the original directory before resuming.

fzf TUI로 최근 세션 목록을 표시하며 각 세션의 **마지막 입력 내용**을 미리보기로 보여줍니다. 선택 시 원래 디렉토리로 자동 이동 후 재개합니다.

| Key | Command |
|-----|---------|
| `Enter` | Last saved mode (persisted across runs) |
| `Ctrl-O` | `claude` |
| `Ctrl-A` | `claude-api` |
| `Ctrl-D` | `claude --dangerously-skip-permissions` |
| `Ctrl-X` | `claude-api --dangerously-skip-permissions` |

**Default command override / 기본 명령어 변경:**

```zsh
export CLAUDE_HISTORY_CMD="claude-api"
# or
export CLAUDE_HISTORY_CMD="claude --dangerously-skip-permissions"
```

**Performance:** ~0.07s first run, ~0.04s subsequent runs (mtime-based cache at `~/.claude/.claude-history-cache.json`)

## After Changes / 설정 변경 후

Restart Claude Code to apply configuration changes.

설정 파일 수정 후 Claude Code를 재시작하면 적용됩니다.
