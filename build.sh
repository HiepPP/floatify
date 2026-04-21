#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT_DIR/Floatify"
PROJECT_FILE="$PROJECT_DIR/Floatify.xcodeproj"
PROJECT_SPEC="$PROJECT_DIR/project.yml"
DERIVED_DATA_PATH="${FLOATIFY_DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/Floatify-local}"
BUILD_PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/Release"
APP_NAME="Floatify"
APP_BUNDLE="$BUILD_PRODUCTS_DIR/$APP_NAME.app"
CLI_BINARY="$BUILD_PRODUCTS_DIR/floatify"
INSTALL_DIR="/Applications"
INSTALLED_APP_BUNDLE="$INSTALL_DIR/$APP_NAME.app"
CLI_LINK="/usr/local/bin/floatify"

cd "$PROJECT_DIR"

# Regenerate only when the project is missing or the spec changed.
if [ ! -d "$PROJECT_FILE" ] || [ "$PROJECT_SPEC" -nt "$PROJECT_FILE" ]; then
    echo "Generating Xcode project..."
    xcodegen generate
fi

mkdir -p "$DERIVED_DATA_PATH"

build_target() {
    local scheme="$1"
    echo "Building $scheme..."
    xcodebuild \
        -project "$PROJECT_FILE" \
        -scheme "$scheme" \
        -configuration Release \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        COMPILER_INDEX_STORE_ENABLE=NO \
        INSTALL_PATH="" \
        SKIP_INSTALL=YES
}

build_target "$APP_NAME"
build_target "floatify"

echo "Prebuilding floater effect frames..."
FLOATIFY_PREBUILD_EFFECTS=1 "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "Quitting existing $APP_NAME..."
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 1

echo "Installing $APP_NAME.app to $INSTALL_DIR..."
ditto "$APP_BUNDLE" "$INSTALLED_APP_BUNDLE"

echo "Symlinking floatify CLI..."
if [ -w "$(dirname "$CLI_LINK")" ]; then
    ln -sf "$CLI_BINARY" "$CLI_LINK"
else
    sudo ln -sf "$CLI_BINARY" "$CLI_LINK"
fi

echo "Build and install complete!"
echo "Reopening $APP_NAME..."
open "$INSTALLED_APP_BUNDLE"
