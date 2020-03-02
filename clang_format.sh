#!/usr/bin/env bash

echo "start formatting files ..."
for file in `find ./ -regex '.*\.[h|m]$'`; do
    clang-format -i ${file} --verbose
done

echo "finish formatting files"
