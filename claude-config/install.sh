#!/bin/bash

# Claude Code dotfiles installer
# Creates symlinks for Claude Code configuration files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/.claude"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude Code dotfiles..."

# Create ~/.claude if it doesn't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"

# Backup and symlink settings.json
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    echo "Backing up existing settings.json to settings.json.backup"
    mv "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
ln -sf "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "Linked: settings.json"

# Backup and symlink statusline-command.sh
if [ -f "$CLAUDE_DIR/statusline-command.sh" ] && [ ! -L "$CLAUDE_DIR/statusline-command.sh" ]; then
    echo "Backing up existing statusline-command.sh to statusline-command.sh.backup"
    mv "$CLAUDE_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh.backup"
fi
ln -sf "$DOTFILES_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
echo "Linked: statusline-command.sh"

# Symlink command files
for cmd in "$DOTFILES_DIR/commands"/*.md; do
    filename=$(basename "$cmd")
    if [ -f "$CLAUDE_DIR/commands/$filename" ] && [ ! -L "$CLAUDE_DIR/commands/$filename" ]; then
        echo "Backing up existing $filename to $filename.backup"
        mv "$CLAUDE_DIR/commands/$filename" "$CLAUDE_DIR/commands/$filename.backup"
    fi
    ln -sf "$cmd" "$CLAUDE_DIR/commands/$filename"
    echo "Linked: commands/$filename"
done

# Add claude-session.zsh source line to ~/.zshrc
ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source $SCRIPT_DIR/sessions.zsh"
if ! grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# Claude Code session management" >> "$ZSHRC"
    echo "$SOURCE_LINE" >> "$ZSHRC"
    echo "Added to ~/.zshrc: $SOURCE_LINE"
else
    echo "Already in ~/.zshrc: $SOURCE_LINE"
fi

echo ""
echo "Installation complete!"
echo "Restart Claude Code to apply changes."
echo "Run 'source ~/.zshrc' to load session management functions."
