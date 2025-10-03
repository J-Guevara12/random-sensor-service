#!/bin/bash

set -e

# Device test: Validate --device flag with edge cases (valid, non-existing, unreadable, short file)

TEMP_DIR="/tmp/device_test_$$"
mkdir -p "$TEMP_DIR"
LOG_FILE="$TEMP_DIR/device_test.log"

cleanup() {
    rm -rf "$TEMP_DIR"
    rm -f stdout.log stderr.log
}
trap cleanup EXIT

echo "Device edge cases test"

# Function for error cases (exits quickly on first read)
test_device_error() {
    local device=$1
    local expected_err_substr=$2
    local desc=$3


    echo "Testing error case: $desc (device=$device, expect '$expected_err_substr')"

    # Run directly, capture stderr
    set +e
    cargo run --quiet -- --device "$device" --interval 1 --logfile "$LOG_FILE" > stdout.log 2> stderr.log
    local exit_code=$?
    set -e

    if [ $exit_code -ne 66 ]; then
        echo "FAIL: Expected exit 66, got $exit_code"
        cat stderr.log
        return 1
    fi

    # Check for error message in stderr (more flexible grep)
    if ! grep -q "Error reading sensor" stderr.log || ! grep -q "$expected_err_substr" stderr.log; then
        echo "FAIL: Expected error message in stderr"
        cat stderr.log
        return 1
    fi

    echo "PASS: $desc - exited 66 with expected error"
    echo "Captured stderr:"
    cat stderr.log
}

# Function for valid case (infinite run, kill after time)
test_device_valid() {
    local device=$1
    local desc=$2

    echo "Testing valid case: $desc (device=$device)"

    # Background run
    cargo run --quiet -- --device "$device" --interval 1 --logfile "$LOG_FILE" > stdout.log 2> stderr.log &
    PID=$!
    sleep 5  # Run for 5s, expect ~4-6 reads

    kill -TERM $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true

    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 143 ]; then
        echo "FAIL: Unexpected exit code $exit_code"
        return 1
    fi

    # Check for sensor logs in file
    if ! grep -q "0x[A-F0-9]\{8\}" "$LOG_FILE"; then
        echo "FAIL: No valid sensor values in log"
        cat "$LOG_FILE"
        cat stderr.log
        return 1
    fi

    echo "PASS: $desc - logs contain values"
    head -3 "$LOG_FILE"  # Show sample
}

# Test 1: Valid /dev/urandom
test_device_valid "/dev/urandom" "valid urandom"
cleanup

# Test 2: Non-existing device
test_device_error "/dev/nonexistent" "No such file or directory" "non-existing"
cleanup

# Test 3: Unreadable file (create + chmod 000)
echo "Creating unreadable file..."
UNREADABLE_FILE="$TEMP_DIR/unreadable_device"
mkdir -p "$TEMP_DIR"
touch "$UNREADABLE_FILE"
chmod 000 "$UNREADABLE_FILE"  # No read permission
test_device_error "$UNREADABLE_FILE" "Permission denied" "unreadable permissions"
cleanup

# Test 4: Short file (<4 bytes)
echo "Creating short file..."
mkdir -p "$TEMP_DIR"
SHORT_FILE="$TEMP_DIR/short_device"
echo -n "AB" > "$SHORT_FILE"  # 2 bytes, readable by default
test_device_error "$SHORT_FILE" "failed to fill whole buffer" "short file"

echo "All device tests passed!"
