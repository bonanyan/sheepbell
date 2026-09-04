#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d build/SheepBell.app ]; then
    ./Scripts/package.sh
fi

pkill -f "SheepBell.app/Contents/MacOS/SheepBell" 2>/dev/null || true
sleep 1
rm -rf /Applications/SheepBell.app
cp -R build/SheepBell.app /Applications/
echo "Installed to /Applications/SheepBell.app"
open /Applications/SheepBell.app
