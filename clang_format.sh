#!/bin/bash

echo "start formatting files ..."
for file in `find ./ -type f -regex '.*\.[h|m]$'`; do
    clang-format -i ${file} --verbose || exit 1
done

echo "finish formatting files"
