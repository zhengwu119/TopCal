#!/bin/bash
#
# build.sh — Build TopCal.app from source.
# Requires Xcode Command Line Tools (swiftc + codesign).
#
# Usage: ./build.sh [output-dir]
#   output-dir  Where to place TopCal.app (default: current directory)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${1:-$ROOT_DIR}"
APP_NAME="TopCal"
APP_BUNDLE="$OUT_DIR/$APP_NAME.app"

echo "==> Building $APP_NAME..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

swiftc \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  -framework AppKit \
  -framework Foundation \
  -framework UserNotifications \
  "$ROOT_DIR/main.swift" \
  "$ROOT_DIR/AppDelegate.swift" \
  "$ROOT_DIR/CalendarViewController.swift" \
  "$ROOT_DIR/LaunchAtLoginManager.swift"

cp "$ROOT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Localization resources (each *.lproj dir)
for lproj in "$ROOT_DIR"/*.lproj; do
  [ -d "$lproj" ] && cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/"
done

# Ad-hoc code signature (no Apple Developer account required)
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
