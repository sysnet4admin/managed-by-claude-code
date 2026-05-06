# Claude Code session management
# Usage: source this file in ~/.zshrc
#   source ~/11.Github/managed-by-claude-code/macOS/claude-session.zsh

# 현재 디렉토리 → Claude 프로젝트 디렉토리 경로 반환
_claude_project_dir() {
  echo "$HOME/.claude/projects/$(pwd | sed 's|/|-|g')"
}

# claude-continue: 현재 디렉토리의 가장 최근 세션으로 resume
claude-continue() {
  local proj_dir=$(_claude_project_dir)
  local latest=$(ls -t "$proj_dir"/*.jsonl 2>/dev/null | head -1)

  if [[ -z "$latest" ]]; then
    echo "[claude-continue] 현재 디렉토리에 저장된 세션 없음: $(pwd)"
    echo "                  새 세션을 시작합니다..."
    claude
    return
  fi

  local session_id=$(basename "$latest" .jsonl)
  local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$latest")
  echo "[claude-continue] 세션 재개: $session_id ($mtime)"
  claude --resume "$session_id"
}

# claude-sessions: 현재 디렉토리의 세션 목록 + 미리보기 (번호 지정 시 resume)
claude-sessions() {
  local proj_dir=$(_claude_project_dir)

  if [[ ! -d "$proj_dir" ]]; then
    echo "[claude-sessions] 세션 없음: $(pwd)"
    return
  fi

  local files=($(ls -t "$proj_dir"/*.jsonl 2>/dev/null))
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "[claude-sessions] 세션 없음: $(pwd)"
    return
  fi

  # 번호 지정 시 해당 세션 resume
  if [[ -n "$1" ]]; then
    local idx=$(( $1 - 1 ))
    local target="${files[$idx]}"
    if [[ -z "$target" ]]; then
      echo "[claude-sessions] [$1] 번 세션 없음"
      return 1
    fi
    local session_id=$(basename "$target" .jsonl)
    local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$target")
    echo "[claude-sessions] [$1] 세션 재개 ($mtime)"
    claude --resume "$session_id"
    return
  fi

  # 목록 + 미리보기 출력
  echo "[claude-sessions] $(pwd) 세션 목록:"
  local i=1
  for f in "${files[@]}"; do
    local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f")
    local preview=$(grep -m 1 '"type":"user"' "$f" 2>/dev/null \
      | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d['message']['content'].split('\n')[0][:60])" 2>/dev/null)
    echo "  [$i] $mtime  ${preview:-(미리보기 없음)}"
    ((i++))
  done
  echo ""
  echo "  재개: claude-sessions <번호>"
}
