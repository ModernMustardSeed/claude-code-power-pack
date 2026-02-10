#!/bin/bash
# Claude Code Hook: Session Logger
# Trigger: PostToolUse (Bash)
# Logs significant operations for session history
#
# To configure, add to your Claude Code hooks:
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Bash",
#       "command": "~/.claude/hooks/session-log.sh"
#     }]
#   }
# }

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/session-$(date +%Y-%m-%d).log"

INPUT=$(cat)

# Log significant operations
if echo "$INPUT" | grep -qE "git (commit|push|merge|rebase)|npm (install|run build)|vercel|railway|docker"; then
    TIMESTAMP=$(date +"%H:%M:%S")
    COMMAND=$(echo "$INPUT" | grep -oP '"command":\s*"\K[^"]+' | head -1 || echo "unknown")
    echo "[$TIMESTAMP] $COMMAND" >> "$LOG_FILE"
fi

exit 0
