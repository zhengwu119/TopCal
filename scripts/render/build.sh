#!/bin/bash
#
# build_render.sh — Build the off-screen screenshot renderer (render.app)
# and produce real AppKit-rendered images into docs/<locale>/.
#
# Usage: ./build_render.sh [locale ...]
#   locale   en | zh-Hans (default: en zh-Hans)
#
# Output: docs/<locale>/screenshot-popover.png + menubar-icon.png
#
# Both files are produced by instantiating the *real* TopCal components
# (CalendarViewController, StatusBarIconRenderer) and exporting them to PNG,
# so the README screenshots reflect the actual UI the app ships.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_BASE="${1:-}"
LOCALES=("${@:2}")
if [ ${#LOCALES[@]} -eq 0 ]; then LOCALES=(en zh-Hans); fi

TMP_DIR="$(mktemp -d -t topcal-render)"
trap "rm -rf $TMP_DIR" EXIT

APP="$TMP_DIR/render.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> Compiling render.app"
swiftc \
  -o "$APP/Contents/MacOS/render" \
  -framework AppKit -framework Foundation -framework UserNotifications \
  $(find "$ROOT_DIR/Sources" -name "*.swift" | grep -v "Sources/main.swift") \
  "$ROOT_DIR/scripts/render/main.swift"

cp "$ROOT_DIR/scripts/render/Info.plist" "$APP/Contents/Info.plist"
cp -R "$ROOT_DIR"/*.lproj "$APP/Contents/Resources/"

for locale in "${LOCALES[@]}"; do
  out_dir="$ROOT_DIR/docs/$locale"
  mkdir -p "$out_dir"
  echo "==> Rendering $locale -> $out_dir"
  "$APP/Contents/MacOS/render" "$locale" "$out_dir"
done

echo "==> Done"