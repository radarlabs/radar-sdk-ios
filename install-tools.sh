#!/bin/bash
#
# Installs the pinned SwiftLint and swift-format into .tools/, so local runs and CI use the same
# versions. To upgrade either tool, change its version here; CI's tool cache is keyed on this file.

set -euo pipefail
cd "$(dirname "$0")"

SWIFTLINT_VERSION="0.63.2"
SWIFT_FORMAT_VERSION="603.0.0"

SWIFTLINT_BIN=".tools/swiftlint"
SWIFT_FORMAT_BIN=".tools/swift-format"

mkdir -p .tools

if [ -x "$SWIFTLINT_BIN" ] && [ "$("$SWIFTLINT_BIN" version 2>/dev/null)" = "$SWIFTLINT_VERSION" ]; then
  echo "swiftlint $SWIFTLINT_VERSION already installed"
else
  echo "installing swiftlint $SWIFTLINT_VERSION..."
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/realm/SwiftLint/releases/download/$SWIFTLINT_VERSION/portable_swiftlint.zip" -o "$TMP/portable_swiftlint.zip"
  unzip -q "$TMP/portable_swiftlint.zip" -d "$TMP"
  mv "$TMP/swiftlint" "$SWIFTLINT_BIN"
  chmod +x "$SWIFTLINT_BIN"
  rm -rf "$TMP"
fi

# swift-format publishes no prebuilt binaries, and Homebrew only installs its latest version, so build
# the pinned tag from source. This takes a few minutes the first time.
if [ -x "$SWIFT_FORMAT_BIN" ] && [ "$("$SWIFT_FORMAT_BIN" --version 2>/dev/null)" = "$SWIFT_FORMAT_VERSION" ]; then
  echo "swift-format $SWIFT_FORMAT_VERSION already installed"
else
  echo "building swift-format $SWIFT_FORMAT_VERSION..."
  TMP=$(mktemp -d)
  git clone --quiet --depth 1 --branch "$SWIFT_FORMAT_VERSION" https://github.com/swiftlang/swift-format.git "$TMP/swift-format"
  swift build --configuration release --package-path "$TMP/swift-format" --product swift-format
  cp "$(swift build --configuration release --package-path "$TMP/swift-format" --show-bin-path)/swift-format" "$SWIFT_FORMAT_BIN"
  rm -rf "$TMP"
  INSTALLED=$("$SWIFT_FORMAT_BIN" --version)
  if [ "$INSTALLED" != "$SWIFT_FORMAT_VERSION" ]; then
    echo "error: built swift-format reports version $INSTALLED, expected $SWIFT_FORMAT_VERSION"
    exit 1
  fi
fi
