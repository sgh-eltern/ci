#!/bin/sh

set -e

if grep -Fxq "true" result/passing; then
  echo Test was successful
else
  echo "Test failed; see $(cat result/screenshot) for why."
  exit 1
fi
