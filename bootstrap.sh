#!/bin/bash

if ! command -v xcodebuild >/dev/null; then
  echo "xcodebuild not installed"
  exit 1
else
  echo "xcodebuild already installed"
fi

if ! command -v gem >/dev/null; then
  echo "rubygems not installed"
  exit 1
else
  echo "rubygems already installed"
fi

if ! command -v brew >/dev/null; then
  echo "homebrew not installed"
  exit 1
else
  echo "homebrew already installed"
fi

if ! command -v xcpretty >/dev/null; then
  echo "installing xcpretty..."
  sudo gem install xcpretty
else
  echo "xcpretty already installed"
fi

if ! command -v jazzy >/dev/null; then
  echo "installing jazzy..."
  sudo gem install jazzy
else
  echo "jazzy already installed"
fi

if ! command -v clang-format >/dev/null; then
  echo "installing clang-format..."
  brew install clang-format
else
  echo "clang-format already installed"
fi

if ! command -v jq >/dev/null; then
  echo "installing jq..."
  brew install jq
else
  echo "jq already installed"
fi

# Pretty-print the SwiftLint baseline (via .gitattributes filter) when it is staged, so its
# diffs are readable instead of one giant minified line. clean-only and non-required: a clone
# without this configured just falls back to SwiftLint's one-line output, no errors.
echo "configuring swiftlint-baseline git clean filter..."
git config filter.swiftlint-baseline.clean "jq -S ."

SWIFTLINT_VERSION="0.63.2"
SWIFTLINT_BIN=".tools/swiftlint"

if [ -f "$SWIFTLINT_BIN" ] && "$SWIFTLINT_BIN" version 2>/dev/null | grep -qx "$SWIFTLINT_VERSION"; then
  echo "swiftlint $SWIFTLINT_VERSION already installed"
else
  echo "installing swiftlint $SWIFTLINT_VERSION..."
  mkdir -p ".tools"
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/realm/SwiftLint/releases/download/$SWIFTLINT_VERSION/portable_swiftlint.zip" -o "$TMP/portable_swiftlint.zip"
  unzip -q "$TMP/portable_swiftlint.zip" -d "$TMP"
  mv "$TMP/swiftlint" "$SWIFTLINT_BIN"
  chmod +x "$SWIFTLINT_BIN"
  rm -rf "$TMP"
fi

# swift-format ships no prebuilt binaries; its version is coupled to the Swift
# toolchain, so brew will install the version matching the active Xcode.
if ! command -v swift-format >/dev/null; then
  echo "installing swift-format..."
  brew install swift-format
else
  echo "swift-format already installed"
fi

echo "dependencies installed"
