#!/bin/sh
# Claude Code status line:
#   dir | ctx used % | session cost | session duration
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Shorten home directory to ~
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# Context used %
ctx_segment=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
  ctx_segment="\033[0;36mctx: ${ctx_int}%\033[0m"
fi

# Session cost — Claude Sonnet 4.x pricing (per million tokens):
#   input: $3.00, output: $15.00, cache write: $3.75, cache read: $0.30
cost_segment=""
if [ "$total_input" -gt 0 ] || [ "$total_output" -gt 0 ] 2>/dev/null; then
  cost=$(echo "$total_input $total_output $cache_creation $cache_read" | awk '{
    input_cost  = $1 * 3.00    / 1000000
    output_cost = $2 * 15.00   / 1000000
    cw_cost     = $3 * 3.75    / 1000000
    cr_cost     = $4 * 0.30    / 1000000
    total = input_cost + output_cost + cw_cost + cr_cost
    printf "$%.4f", total
  }')
  cost_segment="\033[0;33m${cost}\033[0m"
fi

# Session duration — derived from transcript file creation time vs now
duration_segment=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  file_mtime=$(stat -f "%B" "$transcript_path" 2>/dev/null || stat -c "%W" "$transcript_path" 2>/dev/null)
  if [ -z "$file_mtime" ] || [ "$file_mtime" = "0" ]; then
    file_mtime=$(stat -f "%m" "$transcript_path" 2>/dev/null || stat -c "%Y" "$transcript_path" 2>/dev/null)
  fi
  if [ -n "$file_mtime" ]; then
    now=$(date +%s)
    elapsed=$(( now - file_mtime ))
    hours=$(( elapsed / 3600 ))
    minutes=$(( (elapsed % 3600) / 60 ))
    if [ "$hours" -gt 0 ]; then
      duration="${hours}h${minutes}m"
    else
      duration="${minutes}m"
    fi
    duration_segment="\033[0;35m${duration}\033[0m"
  fi
fi

# Assemble — only include segments that have a value
output="\033[0;34m${short_cwd}\033[0m"
for seg in "$ctx_segment" "$cost_segment" "$duration_segment"; do
  if [ -n "$seg" ]; then
    output="${output} | ${seg}"
  fi
done

printf "%b" "$output"
