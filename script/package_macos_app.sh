#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/swift-menubar"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Volcengine TokenPlan Menubar"
PRODUCT_NAME="CodingPlanMenuBar"
BUNDLE_EXECUTABLE="VolcengineTokenPlanMenubar"
BUNDLE_ID="com.songlairui.volcengine-tokenplan-menubar"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

mkdir -p "$DIST_DIR"

pushd "$SWIFT_DIR" >/dev/null
swift build -c release --product "$PRODUCT_NAME"
BUILD_DIR="$(swift build -c release --show-bin-path)"
popd >/dev/null

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$PRODUCT_NAME" "$APP_BUNDLE/Contents/MacOS/$BUNDLE_EXECUTABLE"
chmod +x "$APP_BUNDLE/Contents/MacOS/$BUNDLE_EXECUTABLE"

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>${BUNDLE_EXECUTABLE}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_BUNDLE"

echo "Packaged app bundle at: $APP_BUNDLE"
