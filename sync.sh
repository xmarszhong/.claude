#!/bin/bash
set -e

REPO="https://github.com/xmarszhong/.claude.git"
BRANCH="main"
TARGET="$HOME/.claude"
TMP=$(mktemp -d)

mkdir -p "$TARGET"
git clone --depth=1 --branch "$BRANCH" "$REPO" "$TMP"

rm -rf "$TARGET/.git"

cp -R "$TMP/." "$TARGET/"

rm -rf "$TMP"

echo "已同步 $REPO 的 $BRANCH 分支到 $TARGET"
