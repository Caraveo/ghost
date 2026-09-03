#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$PROJECT_DIR/Ghost.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "==> Building ghost (release)..."
cargo build --release --manifest-path "$PROJECT_DIR/Cargo.toml"

echo "==> Assembling .app bundle..."
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Frameworks"

# Copy binary
cp "$PROJECT_DIR/target/release/ghost" "$CONTENTS/MacOS/ghost"
chmod +x "$CONTENTS/MacOS/ghost"

# Compile Swift settings panel
echo "==> Compiling Swift settings panel..."
SWIFT_SRC="$PROJECT_DIR/settings/Settings.swift"
SWIFT_OUT="$CONTENTS/Frameworks/libghost_settings.dylib"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    SWIFT_TARGET="arm64-apple-macos13.0"
else
    SWIFT_TARGET="x86_64-apple-macos13.0"
fi
swiftc -emit-library "$SWIFT_SRC" \
    -o "$SWIFT_OUT" \
    -framework SwiftUI -framework Cocoa \
    -target "$SWIFT_TARGET" \
    -O 2>&1 || echo "    Swift compilation failed, native settings disabled"
if [ -f "$SWIFT_OUT" ]; then
    echo "    Swift settings panel compiled ($ARCH)"
fi

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Generate .icns from source PNG if available
ICON_SRC="$PROJECT_DIR/ghost Exports/ghost-macOS-Dock-1024x1024.png"
if [ ! -f "$ICON_SRC" ]; then
    ICON_SRC="$PROJECT_DIR/ghost.icon/Assets/ghost.png"
fi
if [ -f "$ICON_SRC" ]; then
    ICONSET="/tmp/ghost.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    # Convert to 8-bit and resize for each required icon size
    sips -s format png "$ICON_SRC" --out /tmp/ghost_icon_8bit.png > /dev/null 2>&1
    SRC8="/tmp/ghost_icon_8bit.png"
    sips -z 16 16 "$SRC8" --out "$ICONSET/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32 "$SRC8" --out "$ICONSET/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32 "$SRC8" --out "$ICONSET/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64 "$SRC8" --out "$ICONSET/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128 "$SRC8" --out "$ICONSET/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256 "$SRC8" --out "$ICONSET/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256 "$SRC8" --out "$ICONSET/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512 "$SRC8" --out "$ICONSET/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$SRC8" --out "$ICONSET/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$SRC8" --out "$ICONSET/icon_512x512@2x.png" > /dev/null 2>&1
    iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns" 2>&1
    rm -rf "$ICONSET" /tmp/ghost_icon_8bit.png
    rm -rf "$ICONSET"
    echo "    icon generated"
else
    echo "    no icon source found, skipping"
fi

# Refresh system icon cache
if command -v touch &>/dev/null; then
    touch "$APP_BUNDLE"
fi

echo "==> Done: $APP_BUNDLE"
echo "    Double-click Ghost.app to launch, or move it to /Applications"
