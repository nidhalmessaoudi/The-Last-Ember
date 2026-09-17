#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/The Last Ember.app"
contents_dir="$app_dir/Contents"
cache_dir="${TMPDIR:-/tmp}/the-last-ember-module-cache"

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources" "$cache_dir"

swiftc -O \
  -module-cache-path "$cache_dir" \
  "$project_dir"/Sources/*.swift \
  -o "$contents_dir/MacOS/TheLastEmber" \
  -framework AppKit \
  -framework SpriteKit \
  -framework AVFoundation

cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
cp "$project_dir/Resources/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"
codesign --force --deep --sign - "$app_dir" >/dev/null

if [[ "${1:-}" == "--test" ]]; then
  "$contents_dir/MacOS/TheLastEmber" --self-test
else
  print "Built: $app_dir"
fi
