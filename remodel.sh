#!/bin/bash

set -e

echo 'remodel files'

tsc \
  --pretty \
  --strictNullChecks \
  -t es2015 \
  -p ./RemodelPlugin \
  --outDir ./RemodelPlugin/bin

## this assumes you have a remodel folder
## TODO: fix this
../remodel/bin/build

../remodel/bin/generate $@

remodelResult=$?

if [[ $remodelResult -ne 0 ]]; then
  echo "Error"
  exit $remodelResult
fi

./clang_format.sh

