#!/bin/bash

if ! command -v clang-format >/dev/null; then
  echo "installing clang-format ..."
  brew install clang-format
else
  echo "clang-format already installed"
fi

git config core.hooksPath .githooks
echo "git hooksPath is configured: $(git config core.hooksPath)"