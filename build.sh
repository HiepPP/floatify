#!/bin/bash
set -e

cd "$(dirname "$0")/Floatify"

# Generate Xcode project if needed
if [ ! -f Floatify.xcodeproj ]; then
    echo "Generating Xcode project..."
    xcodegen generate
fi

# Build app (skip install to avoid lsregister creating duplicates)
echo "Building Floatify.app..."
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
    INSTALL_PATH="" SKIP_INSTALL=YES

# Build CLI
echo "Building floatify CLI..."
xcodebuild -project Floatify.xcodeproj -scheme floatify -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

# Install app to /Applications
echo "Installing Floatify.app to /Applications..."
rm -rf /Applications/Floatify.app
cp -r ~/Library/Developer/Xcode/DerivedData/Floatify-*/Build/Products/Release/Floatify.app /Applications/

# Symlink CLI to /usr/local/bin
echo "Symlinking floatify CLI..."
FLOATIFY_CLI=$(ls -t ~/Library/Developer/Xcode/DerivedData/Floatify-*/Build/Products/Release/floatify 2>/dev/null | head -1)
sudo ln -sf "$FLOATIFY_CLI" /usr/local/bin/floatify

echo "Build and install complete!"
