#!/bin/bash
# Claude Code Hook: Build Check Reporter
# Trigger: PostToolUse (Bash)
# Reports build success/failure after npm run build commands
#
# To configure, add to your Claude Code hooks:
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Bash",
#       "command": "~/.claude/hooks/build-check.sh"
#     }]
#   }
# }

INPUT=$(cat)

# Check if this was a build command
if echo "$INPUT" | grep -qE "npm run build|pnpm build|yarn build|npx next build"; then
    EXIT_CODE=$(echo "$INPUT" | grep -oP '"exit_code":\s*\K[0-9]+' || echo "unknown")

    if [ "$EXIT_CODE" = "0" ]; then
        echo "BUILD: Success" >&2
    elif [ "$EXIT_CODE" != "unknown" ]; then
        echo "BUILD: Failed (exit code $EXIT_CODE)" >&2
        echo "TIP: Check debugging.md for known build patterns" >&2
    fi
fi

exit 0
