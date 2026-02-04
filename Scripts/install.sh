#!/bin/bash
set -e

APP_NAME="ProximityLock"
INSTALL_DIR="$HOME/Applications"
APP_BUNDLE="$INSTALL_DIR/$APP_NAME.app"
BINARY_NAME="ProximityLock"

echo "Building $APP_NAME..."
cd "$(dirname "$0")/.."
swift build -c release

BINARY_PATH=".build/release/$BINARY_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "Creating config directory..."
mkdir -p "$HOME/.config/proximity-lock"

echo ""
echo "Installation complete!"
echo "  App: $APP_BUNDLE"
echo "  Config: $HOME/.config/proximity-lock/config.json"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To enable Launch at Login, use the menu bar option."
