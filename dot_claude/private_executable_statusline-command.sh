#!/bin/sh
# adapted from https://github.com/danielmackay/claude-code-statusline/blob/main/statusline-command.sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // empty')
current_dir=$(echo "$input" | jq -r '.worktree.original_cwd // .workspace.current_dir // .cwd // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | awk '{printf "%.0f", $1}')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | awk '{printf "%.0f", $1}')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$used" ]; then
	used_display=$(printf "%.0f" "$used")
	usage_str="${used_display}%"
else
	usage_str="0%"
fi

if [ -n "$worktree" ]; then
	worktree_str="${worktree}"
else
	worktree_str="no worktree"
fi

GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
RED=$(printf '\033[31m')
ORANGE=$(printf '\033[38;2;255;202;128m')
RESET=$(printf '\033[0m')

git_str=""
if git rev-parse --git-dir >/dev/null 2>&1; then
	branch=$(git branch --show-current 2>/dev/null)
	if [ -z "$branch" ]; then
		hash=$(git rev-parse --short HEAD 2>/dev/null)
		git_str="${GREEN}(${hash})${RESET}"
	else
		git_str="${GREEN}${branch}${RESET}"
	fi

	staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
	modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
	untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
	ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)
	behind=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)

	status_str=""
	[ "$staged" -gt 0 ] && status_str="${status_str}"
	[ "$modified" -gt 0 ] && status_str="${status_str}"
	[ "$untracked" -gt 0 ] && status_str="${status_str}"
	[ "$ahead" -gt 0 ] && status_str="${status_str}⇡${ahead}"
	[ "$behind" -gt 0 ] && status_str="${status_str}⇣${behind}"

	[ -n "$status_str" ] && git_str="${git_str}${ORANGE}${status_str}${RESET}"
else
	git_str="no branch"
fi

make_bar() {
	pct="$1"
	width=10
	filled=$((pct * width / 100))
	bar=""
	i=0
	while [ $i -lt $filled ]; do
		bar="${bar}█"
		i=$((i + 1))
	done
	while [ $i -lt $width ]; do
		bar="${bar}░"
		i=$((i + 1))
	done
	printf "%s" "$bar"
}

format_rl() {
	pct="$1"
	reset_ts="$2"
	label="$3"
	[ -z "$pct" ] && return
	if [ "$pct" -ge 90 ]; then
		color="$RED"
	elif [ "$pct" -ge 70 ]; then
		color="$YELLOW"
	else
		color="$GREEN"
	fi
	reset_time=$(date -r "$reset_ts" "+%-I:%M%p" 2>/dev/null || date -d "@$reset_ts" "+%-I:%M%p" 2>/dev/null)
	bar=$(make_bar "$pct")
	printf "${color}${label} ${bar} ${pct}%%${RESET} resets ${reset_time}"
}

format_rl_short() {
	pct="$1"
	reset_ts="$2"
	label="$3"
	[ -z "$pct" ] && return
	if [ "$pct" -ge 90 ]; then
		color="$RED"
	elif [ "$pct" -ge 70 ]; then
		color="$YELLOW"
	else
		color="$GREEN"
	fi
	printf "${color}${label} ${pct}%%${RESET}"
}

rl_5h_str=$(format_rl "$rl_5h_pct" "$rl_5h_reset" "5h")
rl_7d_str=$(format_rl_short "$rl_7d_pct" "$rl_7d_reset" "7d")
rate_limit_str=""
if [ -n "$rl_5h_str" ] && [ -n "$rl_7d_str" ]; then
	rate_limit_str="${rl_5h_str}, ${rl_7d_str}"
elif [ -n "$rl_5h_str" ]; then
	rate_limit_str="$rl_5h_str"
elif [ -n "$rl_7d_str" ]; then
	rate_limit_str="$rl_7d_str"
fi

repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "$current_dir")
dir_display=$(basename "$repo_root")

case "$model" in
*Sonnet*) model_color="$GREEN" ;;
*) model_color="$YELLOW" ;;
esac
model_display=$(printf '%s%s%s' "$model_color" "$model" "$RESET")

line1="🤖 ${model_display} | 🧠 ${usage_str}"
[ -n "$rate_limit_str" ] && line1="${line1} | ⏱️ ${rate_limit_str}"
line2="📁 ${dir_display} | 🌳 ${worktree_str} | 🌿 ${git_str}"

printf "%s\n%s" "$line1" "$line2"
