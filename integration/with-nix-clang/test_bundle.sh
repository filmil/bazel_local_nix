#!/bin/bash
set -euo pipefail
BUNDLE="$1"
OUTPUT=$("$BUNDLE")
echo "Bundle output: $OUTPUT"
if [[ "$OUTPUT" == *"Hello world!"* ]]; then
  echo "SUCCESS"
  exit 0
else
  echo "FAILURE: Unexpected output"
  exit 1
fi
