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

# 마지막 선택 모드 저장/로드
_claude_mode_file="$HOME/.claude/.claude-history-mode"

_claude_save_mode() {
  echo "$1" > "$_claude_mode_file" 2>/dev/null
}

_claude_load_mode() {
  cat "$_claude_mode_file" 2>/dev/null || echo "default"
}

# 세션 재개 실행 (명령어 모드별 분기)
# CLAUDE_HISTORY_CMD 환경변수로 기본 명령어 설정 가능 (모드 저장보다 우선)
# 예: export CLAUDE_HISTORY_CMD="claude-api"
#     export CLAUDE_HISTORY_CMD="claude --dangerously-skip-permissions"
_claude_resume() {
  local session_id="$1"
  local cwd="$2"
  local mode="${3:-default}"  # default | api | dangerous
  local current_dir="$(pwd)"

  if [[ -n "$cwd" && -d "$cwd" && "$cwd" != "$current_dir" ]]; then
    echo "cd $cwd"
    cd "$cwd"
  fi

  _claude_save_mode "$mode"

  case "$mode" in
    api)           claude-api --resume "$session_id" ;;
    dangerous)     claude --dangerously-skip-permissions --resume "$session_id" ;;
    api-dangerous) claude-api --dangerously-skip-permissions --resume "$session_id" ;;
    *)             ${=CLAUDE_HISTORY_CMD:-claude} --resume "$session_id" ;;
  esac
}

# claude-history: fzf TUI로 전체 세션 목록 표시 및 선택 재개
# 환경변수: CLAUDE_HISTORY_CMD (기본: claude)
# fzf 키:  Enter=기본  Ctrl-A=claude-api  Ctrl-D=--dangerously-skip-permissions
claude-history() {
  local current_dir="$(pwd)"
  local default_cmd="${CLAUDE_HISTORY_CMD:-claude}"

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

  # CLAUDE_HISTORY_CMD 없으면 마지막 선택 모드 사용
  local saved_mode
  if [[ -n "$CLAUDE_HISTORY_CMD" ]]; then
    saved_mode="default"
  else
    saved_mode=$(_claude_load_mode)
  fi

  local session_id cwd mode="$saved_mode"

  # 헤더에 현재 기본 모드 표시
  local enter_label
  case "$saved_mode" in
    api)           enter_label="claude-api" ;;
    dangerous)     enter_label="skip-permissions" ;;
    api-dangerous) enter_label="api+skip" ;;
    *)             enter_label="$default_cmd" ;;
  esac

  if command -v fzf &>/dev/null; then
    # fzf TUI (--expect로 키 구분)
    local result
    result=$(printf '%s\n' "${entries[@]}" \
      | fzf \
        --delimiter=$'\t' \
        --with-nth=3 \
        --height=60% \
        --reverse \
        --prompt="claude> " \
        --header="* 현재 디렉토리 | Enter: ${enter_label}  ^1: claude  ^2: claude-api  ^3: skip-perm  ^4: api+skip  ESC: 취소" \
        --expect=ctrl-1,ctrl-2,ctrl-3,ctrl-4)

    [[ -z "$result" ]] && return

    local key selected
    key=$(echo "$result" | head -1)
    selected=$(echo "$result" | tail -1)
    [[ -z "$selected" ]] && return

    session_id=$(echo "$selected" | cut -f1)
    cwd=$(echo "$selected" | cut -f2)

    case "$key" in
      ctrl-1) mode="default" ;;
      ctrl-2) mode="api" ;;
      ctrl-3) mode="dangerous" ;;
      ctrl-4) mode="api-dangerous" ;;
    esac
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

  _claude_resume "$session_id" "$cwd" "$mode"
}
