#!/bin/bash
set -e

APP_NAME="ProximityLock"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.proximity-lock.agent.plist"
CONFIG_DIR="$HOME/.config/proximity-lock"

echo "Uninstalling $APP_NAME..."

# Stop the app if running
pkill -x "$APP_NAME" 2>/dev/null || true

# Remove LaunchAgent
if [ -f "$LAUNCH_AGENT" ]; then
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT"
    echo "  Removed LaunchAgent"
fi

# Remove app bundle
if [ -d "$APP_BUNDLE" ]; then
    rm -rf "$APP_BUNDLE"
    echo "  Removed app bundle"
fi

echo ""
read -p "Remove config directory ($CONFIG_DIR)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$CONFIG_DIR"
    echo "  Removed config directory"
else
    echo "  Config directory preserved"
fi

echo ""
echo "Uninstall complete."
