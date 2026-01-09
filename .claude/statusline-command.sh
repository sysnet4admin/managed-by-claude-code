#!/bin/bash

# Claude Code Status Line - Display model, context gauge, k8s context, and abbreviated path
# Format: "Model Name | ▓▓▓▓▓░░░░░ | k8s-context | start_dir/.../current_dir"

# Read JSON input from stdin
input=$(cat)

# Helper function to abbreviate path
# Converts /Users/user/11.Github/_Lecture_k8s_starter.kit/ch2
# to 11.Github/.../ch2
abbreviate_path() {
    local path=$1
    local home=$HOME

    # Remove home directory prefix if present
    path=${path#$home/}

    # Split path into components
    IFS='/' read -ra parts <<< "$path"
    local len=${#parts[@]}

    # If 3 or fewer components, show all
    if [ $len -le 3 ]; then
        echo "$path"
        return
    fi

    # Show first component, ..., and last component
    echo "${parts[0]}/.../${parts[-1]}"
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

# Calculate context usage percentage
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
else
    pct=0
fi

# Shorten model name
short_model=$(shorten_model_name "$model")

# Get Kubernetes context
k8s_context=$(get_k8s_context)

# Build status line
abbreviated=$(abbreviate_path "$cwd")

# Output the result with colored gauge
printf "%s | " "$short_model"
create_gauge $pct

# Add k8s context if available (with Kubernetes logo)
if [ -n "$k8s_context" ]; then
    printf " | ☸ %s | %s\n" "$k8s_context" "$abbreviated"
else
    printf " | %s\n" "$abbreviated"
fi
