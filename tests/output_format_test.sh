#!/bin/bash

set -e

# Run the binary in background, capture output

cargo run --quiet > output.log 2>&1 &

PID=$!

# Wait for one iteration (5s sleep + buffer)

sleep 6

# Send SIGTERM to stop

kill -TERM $PID

# Wait for process to exit

wait $PID

# Ensure graceful exit

if ! grep -q "Received SIGTERM, exiting gracefully." output.log; then

    echo "FAIL: No graceful exit"

    cat output.log

    exit 1

fi

# Check for at least one log line with timestamp (ISO-8601 with offset and ns) and uppercase hex

if ! grep -qE '^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{9}[+-][0-9]{2}:[0-9]{2}) \| 0x[A-F0-9]{8}$' output.log; then

    echo "FAIL: No valid timestamp+uppercase hex output"

    cat output.log

    exit 1

fi

echo "PASS: Output format test successful"

rm -f output.log