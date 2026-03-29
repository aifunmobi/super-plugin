#!/bin/bash
# Run all /super plugin tests
# Usage: bash tests/run-all.sh

set -e
cd "$(dirname "$0")/.."

echo ""
echo "Running /super plugin test suite..."
echo ""

FAILED=0

node tests/test-plan-guard.js || FAILED=1
node tests/test-research-tracker.js || FAILED=1
node tests/test-skill-lint.js || FAILED=1

echo ""
if [ $FAILED -eq 0 ]; then
  echo "All test suites passed."
else
  echo "Some tests failed!"
fi
echo ""

exit $FAILED
