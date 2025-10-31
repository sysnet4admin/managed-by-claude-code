#!/bin/bash

# Claude Code Status Line - Display usage information from /status command
# Updates every 60 seconds (1 minute) with cached data

# Read JSON input from stdin first to get session_id
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Use session-specific cache file
CACHE_FILE="$HOME/.claude/.statusline_cache_${session_id}"
CACHE_TTL=60  # Cache time-to-live in seconds (60 = 1 minute)

# Budget limits (calibrated based on actual usage data)
SESSION_BUDGET=2500000  # 5-hour session budget (2.5M tokens)
WEEKLY_BUDGET=30000000  # Weekly budget (30M tokens)
TOTAL_BUDGET=200000     # Context window budget for auto-compress management
AUTOCOMPACT_PCT=22.5    # Autocompact buffer percentage (typically 22.5%)

# Helper function to format numbers in k units
format_k() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        local result=$(awk "BEGIN {printf \"%.1f\", $num/1000000}")
        # Remove .0 if it's a whole number
        result=$(echo "$result" | sed 's/\.0$//')
        echo "${result}M"
    elif [ "$num" -ge 1000 ]; then
        local result=$(awk "BEGIN {printf \"%.1f\", $num/1000}")
        # Remove .0 if it's a whole number
        result=$(echo "$result" | sed 's/\.0$//')
        echo "${result}k"
    else
        echo "$num"
    fi
}

# Debug: Save JSON to file to see what fields are available (session-specific)
echo "$input" > "$HOME/.claude/.statusline_input_debug_${session_id}.json"

# Function to get cache age in seconds
get_cache_age() {
    if [ ! -f "$CACHE_FILE" ]; then
        echo 9999
        return
    fi
    
    local now=$(date +%s)
    local cache_time
    
    # macOS uses -f, Linux uses -c
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    else
        cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    fi
    
    echo $((now - cache_time))
}

# Check if cache is fresh
cache_age=$(get_cache_age)
if [ $cache_age -lt $CACHE_TTL ] && [ -f "$CACHE_FILE" ]; then
    # Cache is fresh, use it
    cat "$CACHE_FILE"
    exit 0
fi

# Cache is stale or doesn't exist, generate new status line

# Extract data from JSON input
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
style=$(echo "$input" | jq -r '.output_style.name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
session_id=$(echo "$input" | jq -r '.session_id // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Initialize result
result=""

# Calculate token usage from transcript JSONL file
current_session_tokens=0
context_tokens=0

# Try to read context from session-specific hook-generated cache first
CONTEXT_CACHE="$HOME/.claude/.context_tokens_cache_${session_id}"
if [ -f "$CONTEXT_CACHE" ]; then
    context_tokens=$(cat "$CONTEXT_CACHE" 2>/dev/null || echo 0)
    if [ -z "$context_tokens" ] || [ "$context_tokens" = "null" ]; then
        context_tokens=0
    fi
fi

if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    # Sum up OUTPUT tokens only (Claude Code usage counts output tokens)
    current_session_tokens=$(jq -s 'map(select(.message.usage) | .message.usage.output_tokens // 0) | add' "$transcript" 2>/dev/null)

    if [ -z "$current_session_tokens" ] || [ "$current_session_tokens" = "null" ]; then
        current_session_tokens=0
    fi

    # Fallback: If hook cache doesn't exist, calculate from transcript
    if [ "$context_tokens" -eq 0 ]; then
        context_tokens=$(jq -s '
            [.[] | select(.type == "assistant" and .message.usage)] |
            .[-1].message.usage |
            ((.cache_read_input_tokens // 0) +
             (.cache_creation_input_tokens // 0) +
             (.input_tokens // 0) +
             16000) // 0
        ' "$transcript" 2>/dev/null)

        if [ -z "$context_tokens" ] || [ "$context_tokens" = "null" ]; then
            context_tokens=0
        fi
    fi
fi

# Calculate session usage (5-hour window)
# Find all session files modified in last 5 hours across all projects
projects_dir="$HOME/.claude/projects"
session_tokens=0
if [ -d "$projects_dir" ]; then
    # Find all .jsonl files modified in last 5 hours (300 minutes)
    five_hours_ago=$(($(date +%s) - 18000))

    for jsonl_file in "$projects_dir"/*/*.jsonl; do
        if [ -f "$jsonl_file" ]; then
            # Get file modification time
            if [[ "$OSTYPE" == "darwin"* ]]; then
                file_time=$(stat -f %m "$jsonl_file" 2>/dev/null || echo 0)
            else
                file_time=$(stat -c %Y "$jsonl_file" 2>/dev/null || echo 0)
            fi

            # If file was modified in last 5 hours, count its tokens
            if [ "$file_time" -ge "$five_hours_ago" ]; then
                tokens=$(jq -s 'map(select(.message.usage) | .message.usage.output_tokens // 0) | add' "$jsonl_file" 2>/dev/null)
                if [ -n "$tokens" ] && [ "$tokens" != "null" ]; then
                    session_tokens=$((session_tokens + tokens))
                fi
            fi
        fi
    done
fi

# Calculate weekly usage (7-day window)
weekly_tokens=0
if [ -d "$projects_dir" ]; then
    # Find all .jsonl files modified in last 7 days
    seven_days_ago=$(($(date +%s) - 604800))

    for jsonl_file in "$projects_dir"/*/*.jsonl; do
        if [ -f "$jsonl_file" ]; then
            # Get file modification time
            if [[ "$OSTYPE" == "darwin"* ]]; then
                file_time=$(stat -f %m "$jsonl_file" 2>/dev/null || echo 0)
            else
                file_time=$(stat -c %Y "$jsonl_file" 2>/dev/null || echo 0)
            fi

            # If file was modified in last 7 days, count its tokens
            if [ "$file_time" -ge "$seven_days_ago" ]; then
                tokens=$(jq -s 'map(select(.message.usage) | .message.usage.output_tokens // 0) | add' "$jsonl_file" 2>/dev/null)
                if [ -n "$tokens" ] && [ "$tokens" != "null" ]; then
                    weekly_tokens=$((weekly_tokens + tokens))
                fi
            fi
        fi
    done
fi

# Build result string
result=""

# 1. Context window usage (from /context)
if [ "$context_tokens" -gt 0 ]; then
    context_fmt=$(format_k $context_tokens)
    total_budget_fmt=$(format_k $TOTAL_BUDGET)
    context_pct=$(awk "BEGIN {printf \"%.0f\", ($context_tokens/$TOTAL_BUDGET)*100}")

    result="Ctx: $context_fmt/$total_budget_fmt ($context_pct%)"
fi

# 2. Session usage (5-hour reset) - Token-based calculation
if [ "$session_tokens" -gt 0 ]; then
    session_fmt=$(format_k $session_tokens)
    session_budget_fmt=$(format_k $SESSION_BUDGET)
    session_pct=$(awk "BEGIN {printf \"%.0f\", ($session_tokens/$SESSION_BUDGET)*100}")
    [ -n "$result" ] && result="$result | "
    result="${result}S: $session_fmt/$session_budget_fmt ($session_pct%)"
fi

# 3. Weekly usage - Token-based calculation
if [ "$weekly_tokens" -gt 0 ]; then
    weekly_fmt=$(format_k $weekly_tokens)
    weekly_budget_fmt=$(format_k $WEEKLY_BUDGET)
    weekly_pct=$(awk "BEGIN {printf \"%.0f\", ($weekly_tokens/$WEEKLY_BUDGET)*100}")
    [ -n "$result" ] && result="$result | "
    result="${result}W: $weekly_fmt/$weekly_budget_fmt ($weekly_pct%)"
fi

# 4. Cost information
if [ -n "$total_cost" ] && [ "$total_cost" != "null" ]; then
    cost_formatted=$(awk "BEGIN {printf \"\$%.2f\", $total_cost}")
    [ -n "$result" ] && result="$result | "
    result="${result}C: $cost_formatted"
fi

# 5. Model information
[ -n "$result" ] && result="$result | "
result="${result}${model}"
if [ -n "$style" ]; then
    result="$result ($style)"
fi

# 6. Current directory
result="$result | $(basename "$cwd")"

# Save to cache and output
echo "$result" > "$CACHE_FILE"
echo "$result"
