#!/bin/bash
# Claude Code Power Pack — Setup Script (macOS/Linux)
# https://github.com/ModernMustardSeed/claude-code-power-pack

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

echo ""
echo "  Claude Code Power Pack — Setup"
echo "  ================================"
echo ""

# Collect user info
read -p "  Your name: " USER_NAME
read -p "  Your email: " USER_EMAIL
read -p "  Your organization (or press Enter to skip): " USER_ORG
USER_ORG="${USER_ORG:-Independent Developer}"

echo ""
echo "  Setting up for: $USER_NAME <$USER_EMAIL> @ $USER_ORG"
echo ""

# Create directories
echo "  [1/7] Creating directory structure..."
mkdir -p "$SKILLS_DIR"
mkdir -p "$CLAUDE_DIR/projects"

# Detect auto-memory path (use generic project path)
# Users will need to adjust this for their specific project paths
MEMORY_DIR="$CLAUDE_DIR/projects/memory"
mkdir -p "$MEMORY_DIR"

# Copy skills
echo "  [2/7] Installing 20 skills..."
SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR"/skills/core/*/  "$SCRIPT_DIR"/skills/workflow/*/ "$SCRIPT_DIR"/skills/productivity/*/; do
    if [ -f "$skill_dir/SKILL.md" ]; then
        skill_name=$(basename "$skill_dir")
        mkdir -p "$SKILLS_DIR/$skill_name"
        cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
        SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
done
echo "         $SKILL_COUNT skills installed"

# Copy and customize CLAUDE.md
echo "  [3/7] Creating root CLAUDE.md..."
if [ ! -f "$HOME/CLAUDE.md" ]; then
    sed -e "s/YOUR_NAME/$USER_NAME/g" \
        -e "s/YOUR_EMAIL/$USER_EMAIL/g" \
        -e "s/YOUR_ORGANIZATION/$USER_ORG/g" \
        "$SCRIPT_DIR/templates/CLAUDE.md" > "$HOME/CLAUDE.md"
    echo "         Created at ~/CLAUDE.md"
else
    echo "         ~/CLAUDE.md already exists — skipping (backup your file if you want to replace it)"
fi

# Copy and customize MEMORY.md
echo "  [4/7] Creating MEMORY.md brain boot sequence..."
if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
    sed -e "s/YOUR_NAME/$USER_NAME/g" \
        -e "s/YOUR_EMAIL/$USER_EMAIL/g" \
        -e "s/YOUR_ORGANIZATION/$USER_ORG/g" \
        "$SCRIPT_DIR/templates/MEMORY.md" > "$MEMORY_DIR/MEMORY.md"
    echo "         Created at $MEMORY_DIR/MEMORY.md"
else
    echo "         MEMORY.md already exists — skipping"
fi

# Copy topic files
echo "  [5/7] Creating topic files..."
for topic_file in "$SCRIPT_DIR"/templates/topic-files/*.md; do
    filename=$(basename "$topic_file")
    if [ ! -f "$MEMORY_DIR/$filename" ]; then
        cp "$topic_file" "$MEMORY_DIR/$filename"
        echo "         Created $filename"
    else
        echo "         $filename already exists — skipping"
    fi
done

# Copy keybindings
echo "  [6/7] Setting up keybindings..."
if [ ! -f "$CLAUDE_DIR/keybindings.json" ]; then
    cp "$SCRIPT_DIR/keybindings.json" "$CLAUDE_DIR/keybindings.json"
    echo "         Keybindings installed"
else
    echo "         keybindings.json already exists — skipping"
fi

# Summary
echo "  [7/7] Verifying installation..."
INSTALLED_SKILLS=$(ls -d "$SKILLS_DIR"/*/SKILL.md 2>/dev/null | wc -l)
HAS_CLAUDE=$(test -f "$HOME/CLAUDE.md" && echo "yes" || echo "no")
HAS_MEMORY=$(test -f "$MEMORY_DIR/MEMORY.md" && echo "yes" || echo "no")
TOPIC_COUNT=$(ls "$MEMORY_DIR"/*.md 2>/dev/null | grep -v MEMORY.md | wc -l)

echo ""
echo "  ================================"
echo "  Setup Complete!"
echo "  ================================"
echo ""
echo "  Skills installed:  $INSTALLED_SKILLS"
echo "  Root CLAUDE.md:    $HAS_CLAUDE"
echo "  MEMORY.md:         $HAS_MEMORY"
echo "  Topic files:       $TOPIC_COUNT"
echo "  Keybindings:       $(test -f "$CLAUDE_DIR/keybindings.json" && echo "yes" || echo "no")"
echo ""
echo "  Next steps:"
echo "  1. Edit ~/CLAUDE.md to add your projects"
echo "  2. Edit MEMORY.md to add your project registry"
echo "  3. Add per-project CLAUDE.md to each project (use templates/project-CLAUDE.md)"
echo "  4. Copy stack modules from stacks/ into your topic files"
echo "  5. Start a Claude Code session and run /boot"
echo ""
echo "  Recommended MCP servers to install:"
echo "  - @anthropic/memory (essential — persistent knowledge graph)"
echo "  - @anthropic/github (essential — PR and repo operations)"
echo "  - @anthropic/sequential-thinking (recommended — complex reasoning)"
echo "  - @anthropic/context7 (recommended — library documentation)"
echo ""
echo "  See mcp-guide/README.md for setup instructions."
echo ""
