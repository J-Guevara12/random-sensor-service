#!/bin/bash

set -e

# Run the binary in background, capture output

cargo run --quiet > output.log 2>&1 &

PID=$!

# Wait for first iteration (5s sleep + buffer)

sleep 6

# Send SIGTERM

kill -TERM $PID

# Wait for process to exit

wait $PID

EXIT_CODE=$?

# Check exit code (should be 0 for graceful exit)

if [ $EXIT_CODE -ne 0 ]; then

    echo "FAIL: Non-zero exit code $EXIT_CODE"

    exit 1

fi

# Check for graceful shutdown message

if ! grep -q "Received SIGTERM, exiting gracefully." output.log; then

    echo "FAIL: No graceful exit message in output"

    cat output.log

    exit 1

fi

# Ensure there was at least one sensor read before termination

if ! grep -q "Read sensor value:" output.log; then

    echo "FAIL: No sensor read output before SIGTERM"

    cat output.log

    exit 1

fi

echo "PASS: SIGTERM handling test successful"

rm -f output.log