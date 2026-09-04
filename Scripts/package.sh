#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild -project SheepBell.xcodeproj -scheme SheepBell -configuration Release build

APP=$(find ~/Library/Developer/Xcode/DerivedData -name SheepBell.app -path "*Release*" | head -1)
if [ -z "$APP" ]; then
    echo "Release build not found" >&2
    exit 1
fi

rm -rf build
mkdir -p build
cp -R "$APP" build/SheepBell.app
codesign --force --deep --sign - build/SheepBell.app

(cd build && zip -qry SheepBell.zip SheepBell.app)
echo "Packaged: build/SheepBell.app and build/SheepBell.zip"
