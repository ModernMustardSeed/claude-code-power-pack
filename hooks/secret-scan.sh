#!/bin/bash
# Claude Code Hook: Secret Scanner
# Trigger: PreToolUse (Write, Edit)
# Scans file content for potential secrets before writing
#
# To configure, add to your Claude Code hooks:
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "~/.claude/hooks/secret-scan.sh"
#     }]
#   }
# }

# Read the tool input from stdin
INPUT=$(cat)

# Patterns that indicate secrets
PATTERNS=(
    "AKIA[0-9A-Z]{16}"                    # AWS Access Key
    "sk-[a-zA-Z0-9]{48}"                  # OpenAI API Key
    "sk-ant-[a-zA-Z0-9-]{90,}"            # Anthropic API Key
    "ghp_[a-zA-Z0-9]{36}"                 # GitHub Personal Access Token
    "gho_[a-zA-Z0-9]{36}"                 # GitHub OAuth Token
    "xoxb-[0-9]{11}-[0-9]{11}-[a-zA-Z0-9]{24}"  # Slack Bot Token
    "sk_live_[a-zA-Z0-9]{24,}"            # Stripe Live Secret Key
    "sq0atp-[a-zA-Z0-9_-]{22}"            # Square Access Token
    "eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*"  # JWT Token
    "-----BEGIN (RSA |EC )?PRIVATE KEY-----"  # Private Keys
    "mongodb(\+srv)?://[^:]+:[^@]+@"       # MongoDB Connection String
    "postgres(ql)?://[^:]+:[^@]+@"         # PostgreSQL Connection String
    "mysql://[^:]+:[^@]+@"                 # MySQL Connection String
    "redis://[^:]+:[^@]+@"                 # Redis Connection String
)

FOUND=0
for pattern in "${PATTERNS[@]}"; do
    if echo "$INPUT" | grep -qE "$pattern"; then
        echo "WARNING: Potential secret detected matching pattern: $pattern" >&2
        FOUND=1
    fi
done

if [ $FOUND -eq 1 ]; then
    echo "BLOCKED: File contains potential secrets. Review the content before writing." >&2
    exit 1
fi

exit 0
