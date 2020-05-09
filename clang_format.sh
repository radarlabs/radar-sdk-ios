#!/bin/bash

echo "formatting files..."
for file in `find ./ -type f -regex '.*\.[h|m]$'`; do
    echo "formatting file ${file}"
    ./bin/clang-format-3.8-custom -i ${file} || exit 1
done
echo "formatted files"
