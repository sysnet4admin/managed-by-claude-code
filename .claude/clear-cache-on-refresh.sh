#!/bin/bash

# Hook script to clear statusline cache when /refresh is executed
# This runs on UserPromptSubmit

# Read hook input JSON from stdin
input=$(cat)

# Extract the user's prompt
user_prompt=$(echo "$input" | jq -r '.prompt // empty')

# If the prompt is /refresh, clear all statusline caches
if [[ "$user_prompt" == "/refresh" ]]; then
    rm -f ~/.claude/.statusline_cache_* 2>/dev/null
fi

# Always exit 0 to allow the command to continue
exit 0
