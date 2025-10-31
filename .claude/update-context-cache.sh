#!/bin/bash

# Hook script to extract context token count and save to cache
# This runs after every tool use

CONTEXT_CACHE="$HOME/.claude/.context_tokens_cache"

# Read hook input JSON from stdin
input=$(cat)

# Extract transcript path from the hook input
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
    exit 0
fi

# Get the most recent assistant message's usage data
# Calculate total input tokens: cache_read + cache_creation + input
# Note: System overhead is already included in cache_read
context_tokens=$(jq -s '
    [.[] | select(.type == "assistant" and .message.usage)] |
    if length > 0 then
        .[-1].message.usage |
        ((.cache_read_input_tokens // 0) +
         (.cache_creation_input_tokens // 0) +
         (.input_tokens // 0))
    else
        0
    end
' "$transcript" 2>/dev/null)

if [ -n "$context_tokens" ] && [ "$context_tokens" != "null" ] && [ "$context_tokens" -gt 0 ]; then
    echo "$context_tokens" > "$CONTEXT_CACHE"
fi
