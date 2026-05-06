# Claude Code session management
# Usage: source this file in ~/.zshrc
#   source ~/11.Github/managed-by-claude-code/claude-config/claude-history.zsh

# 모든 파일을 단일 python3 프로세스로 처리 (캐시 활용)
# 캐시: ~/.claude/.claude-history-cache.json
# 출력: filepath\tcwd\tpreview\n
_claude_extract_all() {
  python3 - "$@" <<'PYEOF'
import sys, json, os

CACHE_FILE = os.path.expanduser('~/.claude/.claude-history-cache.json')

def extract(filepath):
    size = os.path.getsize(filepath)
    cwd = ''
    first_preview = ''

    with open(filepath, 'r', errors='ignore') as f:
        for i, line in enumerate(f):
            if i > 50:
                break
            try:
                d = json.loads(line.strip())
                if d.get('type') == 'user' and not cwd:
                    cwd = d.get('cwd', '')
                    content = d.get('message', {}).get('content', '')
                    if isinstance(content, str) and not content.startswith('<'):
                        first_preview = content.split('\n')[0][:80]
            except:
                pass

    last_prompt = ''
    with open(filepath, 'rb') as f:
        f.seek(max(0, size - 20480))
        tail = f.read().decode('utf-8', errors='ignore')
    for line in reversed(tail.split('\n')):
        try:
            d = json.loads(line.strip())
            if d.get('type') == 'last-prompt':
                p = d.get('lastPrompt', '')
                if p and not p.startswith('<'):
                    last_prompt = p.split('\n')[0][:80]
                    break
        except:
            pass

    return cwd, last_prompt or first_preview

def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except:
        return {}

def save_cache(cache):
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(cache, f)
    except:
        pass

cache = load_cache()
new_cache = {}

for f in sys.argv[1:]:
    try:
        mtime = os.path.getmtime(f)
        entry = cache.get(f)
        if entry and entry.get('mtime') == mtime:
            cwd, preview = entry['cwd'], entry['preview']
        else:
            cwd, preview = extract(f)
        new_cache[f] = {'mtime': mtime, 'cwd': cwd, 'preview': preview}
        print(f'{f}\t{cwd}\t{preview}', flush=True)
    except:
        print(f'{f}\t\t', flush=True)

save_cache(new_cache)
PYEOF
}

# claude-continue: 현재 디렉토리 최신 세션 재개 (claude -c 래퍼)
claude-continue() {
  claude --continue "$@"
}

# claude-history: fzf TUI로 전체 세션 목록 표시 및 선택 재개
claude-history() {
  local current_dir="$(pwd)"

  # 최근 100개 세션 파일 목록
  local files=()
  while IFS= read -r f; do
    [[ -f "$f" ]] && files+=("$f")
  done < <(find "$HOME/.claude/projects" -maxdepth 2 -name "*.jsonl" ! -path "*/subagents/*" \
    -exec stat -f '%m %N' {} + 2>/dev/null | sort -rn | awk '{print $2}' | head -100)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "[claude-history] 세션 없음"
    return
  fi

  # 단일 python3로 전체 파일 처리
  local entries=()
  while IFS=$'\t' read -r filepath cwd preview; do
    local session_id=$(basename "$filepath" .jsonl)
    local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$filepath")
    local short_cwd="${cwd/#$HOME/~}"
    local marker="  "
    [[ "$cwd" == "$current_dir" ]] && marker="* "
    entries+=("${session_id}	${cwd}	${marker}${mtime}  ${short_cwd}: ${preview:-(미리보기 없음)}")
  done < <(_claude_extract_all "${files[@]}")

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
    printf "번호 선택 (q: 취소): "
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
