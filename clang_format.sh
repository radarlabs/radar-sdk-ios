#!/bin/bash

echo "formatting files..."
for file in `find ./ -type f -regex '.*\.[h|m]$'`; do
    clang-format -i ${file} --verbose || exit 1
done
echo "formatted files"
