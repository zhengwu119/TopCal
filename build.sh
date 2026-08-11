#!/bin/bash
#
# build.sh — Build MenuBarCalendar.app from source.
# Requires Xcode Command Line Tools (swiftc + codesign).
#
# Usage: ./build.sh [output-dir]
#   output-dir  Where to place MenuBarCalendar.app (default: current directory)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${1:-$ROOT_DIR}"
APP_NAME="MenuBarCalendar"
APP_BUNDLE="$OUT_DIR/$APP_NAME.app"

echo "==> Building $APP_NAME..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

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

# Ad-hoc code signature (no Apple Developer account required)
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
