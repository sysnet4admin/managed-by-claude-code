# Claude Code Config

여러 노트북에서 동일한 Claude Code 글로벌 설정을 사용하기 위한 설정 파일입니다.

## 구조

```
claude-config/
├── .claude/
│   ├── settings.json         # 글로벌 설정 (statusline, attribution 등)
│   ├── statusline-command.sh # 커스텀 statusline
│   └── commands/             # 슬래시 명령어
│       ├── h.md              # /h - Haiku 모델
│       ├── o.md              # /o - Opus 모델
│       └── s.md              # /s - Sonnet 모델
├── install.sh                # 설치 스크립트
└── README.md
```

## 설치

```bash
cd claude-config
./install.sh
```

설치 스크립트는 `~/.claude/`에 symlink를 생성합니다. 기존 파일이 있으면 `.backup`으로 백업됩니다.

## Statusline 기능

- 모델명 표시 (Opus 4.5, Sonnet 4.5 등)
- 컨텍스트 사용량 게이지 (색상: 초록 <50%, 노랑 50-70%, 빨강 ≥70%)
- Kubernetes 컨텍스트 표시 (☸ 아이콘)
- 현재 경로 (축약형)

예시: `Opus 4.5 | ▓▓▓░░░░░░░ | ☸ my-cluster | project/.../src`

## 설정 변경 후

설정 파일 수정 후 Claude Code를 재시작하면 적용됩니다.
