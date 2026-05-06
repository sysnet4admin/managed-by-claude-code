# Claude Code session management
# Usage: source this file in ~/.zshrc
#   source ~/11.Github/managed-by-claude-code/claude-config/sessions.zsh

# JSONL에서 마지막 유효 메시지 미리보기 추출
_claude_session_preview() {
  local f="$1"
  # last-prompt 타입 우선 (마지막 사용자 입력)
  local preview
  preview=$(grep '"type":"last-prompt"' "$f" 2>/dev/null | tail -1 | python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
prompt = d.get('lastPrompt', '')
if prompt and not prompt.startswith('<'):
    print(prompt.split('\n')[0][:80])
" 2>/dev/null)

  # fallback: 첫 user 메시지
  if [[ -z "$preview" ]]; then
    preview=$(grep -m 1 '"type":"user"' "$f" 2>/dev/null | python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
content = d['message']['content']
if isinstance(content, str) and not content.startswith('<'):
    print(content.split('\n')[0][:80])
" 2>/dev/null)
  fi
  echo "$preview"
}

# JSONL에서 cwd 추출
_claude_session_cwd() {
  grep -m 1 '"type":"user"' "$1" 2>/dev/null \
    | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('cwd',''))" 2>/dev/null
}

# claude-continue: 현재 디렉토리 최신 세션 재개 (claude -c 래퍼)
claude-continue() {
  claude --continue "$@"
}

# claude-history: fzf TUI로 전체 세션 목록 표시 및 선택 재개
claude-history() {
  local entries=()
  local current_dir="$(pwd)"

  # 최근 100개 세션 수집
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f")
    local session_id=$(basename "$f" .jsonl)
    local cwd=$(_claude_session_cwd "$f")
    local preview=$(_claude_session_preview "$f")
    local short_cwd="${cwd/#$HOME/~}"

    # 현재 디렉토리 세션 표시
    local marker="  "
    [[ "$cwd" == "$current_dir" ]] && marker="* "

    entries+=("${session_id}	${cwd}	${marker}${mtime}  ${short_cwd}: ${preview:-(미리보기 없음)}")
  done < <(find "$HOME/.claude/projects" -maxdepth 2 -name "*.jsonl" ! -path "*/subagents/*" \
    -exec stat -f '%m %N' {} \; 2>/dev/null | sort -rn | awk '{print $2}' | head -100)

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "[claude-history] 세션 없음"
    return
  fi

  local session_id cwd selected

  if command -v fzf &>/dev/null; then
    # fzf TUI
    selected=$(printf '%s\n' "${entries[@]}" \
      | fzf \
        --delimiter=$'\t' \
        --with-nth=3 \
        --height=60% \
        --reverse \
        --prompt="claude> " \
        --header="* 현재 디렉토리 | Enter: 재개  ESC: 취소")
    [[ -z "$selected" ]] && return
    session_id=$(echo "$selected" | cut -f1)
    cwd=$(echo "$selected" | cut -f2)
  else
    # fallback: 번호 목록 (fzf 미설치)
    echo "[claude-history] TUI를 사용하려면 fzf를 설치하세요: brew install fzf"
    echo "[claude-history] 세션 목록: (* 현재 디렉토리)"
    local i=1
    for entry in "${entries[@]}"; do
      echo "  [$i] $(echo "$entry" | cut -f3)"
      ((i++))
    done
    echo ""
    printf "번호 선택 (ESC/q: 취소): "
    read -r pick
    [[ -z "$pick" || "$pick" == "q" ]] && return
    if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#entries[@]} )); then
      echo "잘못된 번호"
      return 1
    fi
    local target="${entries[$((pick - 1))]}"
    session_id=$(echo "$target" | cut -f1)
    cwd=$(echo "$target" | cut -f2)
  fi

  if [[ -n "$cwd" && -d "$cwd" && "$cwd" != "$current_dir" ]]; then
    echo "cd $cwd"
    cd "$cwd"
  fi

  claude --resume "$session_id"
}
