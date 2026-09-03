#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$PROJECT_DIR/Ghost.app"
CONTENTS="$APP_BUNDLE/Contents"

if [ "${UNIVERSAL:-0}" = "1" ]; then
    echo "==> Building ghost universal release..."
    cargo build --release --target x86_64-apple-darwin --manifest-path "$PROJECT_DIR/Cargo.toml"
    cargo build --release --target aarch64-apple-darwin --manifest-path "$PROJECT_DIR/Cargo.toml"
else
    echo "==> Building ghost (release)..."
    cargo build --release --manifest-path "$PROJECT_DIR/Cargo.toml"
fi

echo "==> Assembling .app bundle..."
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Frameworks"

# Copy or combine the executable.
if [ "${UNIVERSAL:-0}" = "1" ]; then
    lipo -create \
        "$PROJECT_DIR/target/x86_64-apple-darwin/release/ghost" \
        "$PROJECT_DIR/target/aarch64-apple-darwin/release/ghost" \
        -output "$CONTENTS/MacOS/ghost"
else
    cp "$PROJECT_DIR/target/release/ghost" "$CONTENTS/MacOS/ghost"
fi
chmod +x "$CONTENTS/MacOS/ghost"

# Compile Swift settings panel
echo "==> Compiling Swift settings panel..."
SWIFT_SRC="$PROJECT_DIR/settings/Settings.swift"
SWIFT_OUT="$CONTENTS/Frameworks/libghost_settings.dylib"
if [ "${UNIVERSAL:-0}" = "1" ]; then
    SWIFT_X86="${TMPDIR:-/tmp}/libghost_settings_x86_64.dylib"
    SWIFT_ARM="${TMPDIR:-/tmp}/libghost_settings_arm64.dylib"
    swiftc -emit-library "$SWIFT_SRC" -o "$SWIFT_X86" \
        -framework SwiftUI -framework Cocoa -target x86_64-apple-macos13.0 -O
    swiftc -emit-library "$SWIFT_SRC" -o "$SWIFT_ARM" \
        -framework SwiftUI -framework Cocoa -target arm64-apple-macos13.0 -O
    lipo -create "$SWIFT_X86" "$SWIFT_ARM" -output "$SWIFT_OUT"
    rm -f "$SWIFT_X86" "$SWIFT_ARM"
    echo "    Swift settings panel compiled (universal)"
else
    ARCH=$(uname -m)
    SWIFT_TARGET="${ARCH}-apple-macos13.0"
    swiftc -emit-library "$SWIFT_SRC" -o "$SWIFT_OUT" \
        -framework SwiftUI -framework Cocoa -target "$SWIFT_TARGET" -O
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

if [ -n "${SIGN_IDENTITY:-}" ]; then
    echo "==> Signing with $SIGN_IDENTITY..."
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" \
        "$CONTENTS/Frameworks/libghost_settings.dylib"
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" \
        "$CONTENTS/MacOS/ghost"
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
fi

echo "==> Done: $APP_BUNDLE"
echo "    Double-click Ghost.app to launch, or move it to /Applications"
