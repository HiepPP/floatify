#!/bin/bash
# Safe install script - no sudo required.
# - Builds Floatify.app and floatify CLI.
# - Installs app to /Applications via ditto (admin group is writable by default).
# - Symlinks CLI into the first user-writable bin directory on PATH.
set -e

cd "$(dirname "$0")/Floatify"

# Generate Xcode project if missing
if [ ! -d Floatify.xcodeproj ]; then
    echo "Generating Xcode project..."
    xcodegen generate
fi

# Build app
echo "Building Floatify.app..."
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
    INSTALL_PATH="" SKIP_INSTALL=YES

# Build CLI
echo "Building floatify CLI..."
xcodebuild -project Floatify.xcodeproj -scheme floatify -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

# Locate fresh build outputs
APP_SOURCE=$(ls -td ~/Library/Developer/Xcode/DerivedData/Floatify-*/Build/Products/Release/Floatify.app 2>/dev/null | head -1)
CLI_SOURCE=$(ls -t  ~/Library/Developer/Xcode/DerivedData/Floatify-*/Build/Products/Release/floatify 2>/dev/null | head -1)

if [ -z "$APP_SOURCE" ] || [ -z "$CLI_SOURCE" ]; then
    echo "Build output not found in DerivedData" >&2
    exit 1
fi

# Quit running Floatify so the bundle can be replaced
echo "Quitting existing Floatify..."
pkill -x Floatify || true
sleep 1

# Check /Applications is writable by this user (admin group default on macOS)
if [ ! -w /Applications ]; then
    echo "/Applications is not writable by current user." >&2
    echo "Run this script as an admin user, or install Floatify.app manually." >&2
    exit 1
fi

# Install app bundle in-place (ditto preserves bundle metadata, no rm -rf)
echo "Installing Floatify.app to /Applications..."
ditto "$APP_SOURCE" /Applications/Floatify.app

# Pick first user-writable bin directory on PATH
TARGET_DIR=""
for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        TARGET_DIR="$dir"
        break
    fi
done

# Fallback: create ~/.local/bin
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/.local/bin"
    mkdir -p "$TARGET_DIR"
    echo "Created $TARGET_DIR"
fi

TARGET="$TARGET_DIR/floatify"
echo "Symlinking CLI to $TARGET..."
ln -sf "$CLI_SOURCE" "$TARGET"

# Warn if target dir is not on PATH
case ":$PATH:" in
    *":$TARGET_DIR:"*) ;;
    *)
        echo
        echo "Note: $TARGET_DIR is not on your PATH."
        echo "Add this line to your shell rc (~/.zshrc or ~/.bashrc):"
        echo "  export PATH=\"$TARGET_DIR:\$PATH\""
        ;;
esac

echo "Install complete!"

# Launch fresh app
echo "Launching Floatify..."
open /Applications/Floatify.app
