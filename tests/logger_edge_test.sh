#!/bin/bash

set -e

# Logger edge cases test: non-writable files, invalid paths, fallback to stderr

# Unique log names to avoid conflicts
PRIMARY_LOG="/tmp/sensor_edge_$(date +%s).log"
FALLBACK_LOG="/var/tmp/sensor_edge_$(date +%s).log"
INVALID_LOG="/tmp/nonexistent_dir/sensor_edge.log"

# Cleanup function
cleanup_test_files() {
    rm -f "$PRIMARY_LOG" "$FALLBACK_LOG" /tmp/sensor_edge*.log /var/tmp/sensor_edge*.log stdout.log stderr.log
}
trap cleanup_test_files EXIT

# Function to run binary for fixed time and check
run_binary() {
    local logfile=$1
    local interval=$2
    local expected_log=$3  # "" for stderr fallback
    local short_desc=$4

    echo "Running $short_desc: logfile=$logfile, interval=$interval"

    cargo run --quiet -- --logfile "$logfile" --interval "$interval" > stdout.log 2> stderr.log &

    PID=$!

    # Wait for a few iterations (1s sleep + buffer)

    sleep 3

    # Send SIGTERM

    kill -TERM $PID

    # Wait for process to exit

    wait $PID


    if [ $? -ne 124 ] && [ $? -ne 0 ]; then
        echo "FAIL: Unexpected exit code for $short_desc"
        return 1
    fi

    # Check if log has content (sensors read)
    local has_log=false
    if [ -n "$expected_log" ] && [ -f "$expected_log" ]; then
        if grep -q "0x[A-F0-9]\{8\}" "$expected_log"; then
            has_log=true
            echo "PASS: $short_desc - logged to $expected_log"
        fi
    fi

    if [ "$has_log" = false ]; then
        # Check stderr
        if grep -q "0x[A-F0-9]\{8\}" stderr.log; then
            echo "PASS: $short_desc - fallback to stderr"
            head -5 stderr.log
        else
            echo "FAIL: No logs found in $expected_log or stderr for $short_desc"
            cat stderr.log
            return 1
        fi
    fi
}

# Test 1: Baseline - writable primary
echo "=== Test 1: Baseline writable primary ==="
run_binary "$PRIMARY_LOG" 1 "$PRIMARY_LOG" "baseline"

# Test 2: Non-writable primary - create read-only file, expect fallback
echo "=== Test 2: Non-writable primary, expect fallback ==="
touch "$PRIMARY_LOG"
chmod 444 "$PRIMARY_LOG"  # Read-only
run_binary "$PRIMARY_LOG" 1 "$FALLBACK_LOG" "non-writable primary"

# Test 3: Invalid path - expect stderr
echo "=== Test 3: Invalid log path, expect stderr ==="
run_binary "$INVALID_LOG" 1 "" "invalid path"

# Test 4: Primary writable but short interval to ensure multiple entries
echo "=== Test 4: Writable with short interval ==="
rm -f "$PRIMARY_LOG"
run_binary "$PRIMARY_LOG" 1 "$PRIMARY_LOG" "short interval"

# Test 5: Simulate both unwritable by using read-only dir for primary and fallback
echo "=== Test 5: Both paths in read-only dir, expect stderr ==="
RO_DIR="/tmp/ro_test_$(date +%s)"
mkdir "$RO_DIR"
chmod 555 "$RO_DIR"  # Read-only dir
RO_PRIMARY="$RO_DIR/primary.log"
RO_FALLBACK="$RO_DIR/fallback.log"
run_binary "$RO_PRIMARY" 1 "" "read-only dir (both fail)"

# Cleanup the RO dir
rmdir "$RO_DIR" 2>/dev/null || true

echo "All tests passed!"
