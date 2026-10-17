#!/bin/zsh
# 릴리스 빌드를 Finder 빠른 동작이 실행하는 경로에 설치한다.
# 빠른 동작: ~/Library/Services/가로로 이어붙이기.workflow
#            ~/Library/Services/세로로 이어붙이기.workflow
set -euo pipefail

root="${0:A:h:h}"
dest="$HOME/Library/Application Support/QuickTools"
cd "$root"

swift build -c release
mkdir -p "$dest"
cp -f "$root/.build/release/piconnect" "$dest/piconnect"
chmod +x "$dest/piconnect"
codesign --force --sign - "$dest/piconnect"
echo "설치됨: $dest/piconnect"
