#!/bin/bash

set -e

# Run all tests in tests/ folder (project root assumed as cwd)

echo "Running all integration tests..."

TEST_DIR="tests"
FAILED=0

for test_script in "$TEST_DIR"/*.sh; do
    if [ -f "$test_script" ] && [[ "$test_script" =~ \.sh$ ]]; then
        script_name=$(basename "$test_script")
        echo "=== Running $script_name ==="
        if "$test_script"; then
            echo "PASS: $script_name"
        else
            echo "FAIL: $script_name"
            FAILED=1
        fi
        echo ""
    fi
done

if [ $FAILED -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "$FAILED tests failed. Check output above."
    exit $FAILED
fi