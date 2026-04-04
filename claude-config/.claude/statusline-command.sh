#!/bin/bash

# Claude Code Status Line - Display model, context gauge, usage limits, k8s context, and abbreviated path
# Format: "Model Name | ▓▓▓▓▓░░░░░ | 5h:XX% 7d:XX% | k8s-context | start_dir/.../current_dir"

# Read JSON input from stdin
input=$(cat)

# Format usage limits from stdin JSON (no external API calls needed)
format_usage_limits() {
    local input=$1

    local five_hour_pct
    five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)

    if [ -z "$five_hour_pct" ]; then
        echo ""
        return
    fi

    local five_int=${five_hour_pct%.*}
    local five_color
    if [ "$five_int" -lt 50 ]; then
        five_color="\033[32m"  # Green
    elif [ "$five_int" -lt 80 ]; then
        five_color="\033[33m"  # Yellow
    else
        five_color="\033[31m"  # Red
    fi

    local resets_at
    resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)

    if [ -n "$resets_at" ] && [ "$resets_at" != "null" ]; then
        local now_epoch
        now_epoch=$(date "+%s")
        local reset_secs=$((resets_at - now_epoch))
        if [ $reset_secs -le 0 ]; then reset_secs=0; fi
        local hours=$((reset_secs / 3600))
        local mins=$(((reset_secs % 3600) / 60))
        local remaining
        if [ $hours -gt 0 ]; then
            remaining=$(printf "%dh%dm" $hours $mins)
        else
            remaining=$(printf "%dm" $mins)
        fi
        echo "${five_color}${five_int}%\033[0m (Rst:${remaining})"
    else
        echo "${five_color}${five_int}%\033[0m"
    fi
}

# Helper function to abbreviate path
# Priority: current folder (last) must always be fully visible
# Format: .../<current_folder> or <short_first>/.../<current_folder>
abbreviate_path() {
    local path=$1
    local home=$HOME
    local max_first_len=8  # Max length for first component

    # Remove home directory prefix if present
    path=${path#$home/}

    # Split path into components
    IFS='/' read -ra parts <<< "$path"
    local len=${#parts[@]}

    # If only 1 component, show as is
    if [ $len -le 1 ]; then
        echo "$path"
        return
    fi

    # If 2 components, show both
    if [ $len -eq 2 ]; then
        echo "$path"
        return
    fi

    # For 3+ components: abbreviate first, keep last in full
    local first="${parts[0]}"
    local last="${parts[$((len-1))]}"

    # Truncate first component if too long
    if [ ${#first} -gt $max_first_len ]; then
        first="${first:0:$max_first_len}"
    fi

    echo "${first}/…/${last}"
}

# Helper function to create visual gauge with color
# Takes percentage (0-100) and returns a 10-character gauge with ANSI color
# Color scheme:
#   < 60%: Green (safe)
#   60-79%: Yellow (warning)
#   >= 80%: Red (danger/compression imminent)
create_gauge() {
    local pct=$1
    local filled=$((pct / 10))
    local empty=$((10 - filled))

    # Determine color based on percentage
    local color
    if [ $pct -lt 50 ]; then
        color="\033[32m"  # Green
    elif [ $pct -lt 70 ]; then
        color="\033[33m"  # Yellow
    else
        color="\033[31m"  # Red
    fi
    local reset="\033[0m"

    # Build gauge string with color
    local gauge=""
    for ((i=0; i<filled; i++)); do
        gauge="${gauge}▓"
    done
    for ((i=0; i<empty; i++)); do
        gauge="${gauge}░"
    done

    # Apply color to the gauge
    printf "${color}${gauge}${reset}"
}

# Helper function to shorten model name
shorten_model_name() {
    local name=$1
    # Claude Opus 4.5 -> Opus 4.5
    # Claude Sonnet 4.5 -> Sonnet 4.5
    # Claude 3.5 Sonnet -> Sonnet 3.5
    name=$(echo "$name" | sed 's/^Claude //')
    echo "$name"
}

# Helper function to get and abbreviate Kubernetes context
get_k8s_context() {
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo ""
        return
    fi

    # Get current context
    local context=$(kubectl config current-context 2>/dev/null)

    # If no context, return empty
    if [ -z "$context" ]; then
        echo ""
        return
    fi

    # Abbreviate context name
    # kubernetes-admin@cluster -> cluster
    # arn:aws:eks:region:account:cluster/name -> name
    local abbreviated="$context"

    # Remove kubernetes-admin@ prefix
    abbreviated=$(echo "$abbreviated" | sed 's/^kubernetes-admin@//')

    # Extract cluster name from AWS EKS ARN format
    if [[ "$abbreviated" =~ cluster/([^/]+)$ ]]; then
        abbreviated="${BASH_REMATCH[1]}"
    fi

    # Extract from other common patterns
    # user@cluster -> cluster
    if [[ "$abbreviated" =~ @(.+)$ ]]; then
        abbreviated="${BASH_REMATCH[1]}"
    fi

    echo "$abbreviated"
}

# Extract data from JSON input
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Context usage percentage (directly from Claude Code)
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
pct=${pct%.*}  # Remove decimal part

# Shorten model name
short_model=$(shorten_model_name "$model")

# Get Kubernetes context
k8s_context=$(get_k8s_context)

# Build status line
abbreviated=$(abbreviate_path "$cwd")

# Get usage limits from stdin JSON
usage_display=$(format_usage_limits "$input")

# Output the result with colored gauge
printf "%s | " "$short_model"
create_gauge $pct

# Add usage limits if available
if [ -n "$usage_display" ]; then
    printf " | "
    printf "%b" "$usage_display"
fi

# Add k8s context if available
if [ -n "$k8s_context" ]; then
    printf " | %s | %s\n" "$k8s_context" "$abbreviated"
else
    printf " | %s\n" "$abbreviated"
fi
