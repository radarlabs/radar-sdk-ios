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

echo "dependencies installed"
