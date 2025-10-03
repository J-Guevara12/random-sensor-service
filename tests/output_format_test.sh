#!/bin/bash

set -e

# Cleanup previous logs
rm -f /tmp/random_sensor.log /var/tmp/random_sensor.log

# Run the binary in background (no output redirect, logs go to file)

cargo run --quiet &

PID=$!

# Wait for a few iterations (500ms sleep + buffer)

sleep 3

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

# Function to check log file

check_log() {

    local log_path=$1

    if ! [ -f "$log_path" ]; then

        echo "No log file at $log_path"

        return 1

    fi

    # Check for graceful shutdown message

    if ! grep -q "Received SIGTERM, exiting gracefully." "$log_path"; then

        echo "FAIL: No graceful exit message in $log_path"

        cat "$log_path"

        return 1

    fi

    # Check for at least one log line with timestamp (ISO-8601 with Z or offset and ns) and uppercase hex

    if ! grep -qE '^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{9}(Z|[+-][0-9]{2}:[0-9]{2})) \| 0x[A-F0-9]{8}$' "$log_path"; then

        echo "FAIL: No valid timestamp+uppercase hex output in $log_path"

        cat "$log_path"

        return 1

    fi

    # Ensure there was at least one sensor read before termination

    if ! grep -qE '0x[A-F0-9]{8}' "$log_path"; then

        echo "FAIL: No sensor read output before SIGTERM in $log_path"

        cat "$log_path"

        return 1

    fi

    echo "PASS for $log_path"

    return 0

}

# Check primary log

if check_log "/tmp/random_sensor.log"; then

    echo "PASS: Output format test successful"

    rm -f /tmp/random_sensor.log /var/tmp/random_sensor.log

    exit 0

fi

# Check fallback log

if check_log "/var/tmp/random_sensor.log"; then

    echo "PASS: Output format test successful (fallback)"

    rm -f /tmp/random_sensor.log /var/tmp/random_sensor.log

    exit 0

fi

echo "FAIL: No valid log files found"

exit 1
