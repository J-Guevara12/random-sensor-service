#!/bin/bash

set -e

# Interval test: Assert sampling rate changes with --interval (default 5s, >0)

PRIMARY_LOG="/tmp/interval_test.log"

cleanup() {
    rm -f "$PRIMARY_LOG" stdout.log stderr.log
}
trap cleanup EXIT

run_interval_test() {
    local interval=$1
    local expected_count_min=$2
    local expected_count_max=$3
    local desc=$4

    echo "Testing --interval $interval ($desc)"

    cleanup  # Fresh log

    if [ "$interval" == "error" ]; then
        cargo run --quiet -- --interval 0 > stdout.log 2> stderr.log &

        PID=$!

        wait $PID 2>/dev/null || true

        if ! grep -q "must be greater than 0" stderr.log; then
            echo "FAIL: Expected error for interval 0, but no error message"
            cat stderr.log
            return 1
        fi
        echo "PASS: Invalid interval 0 exits with error"
        return 0
    fi

    # Run for ~8s to allow multiple reads (interval-dependent)
    cargo run --quiet -- --interval "$interval" --logfile "$PRIMARY_LOG" > stdout.log 2> stderr.log &

    PID=$!
    sleep 8  # Run for 8s

    kill -TERM $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true

    # Count sensor log entries (timestamp | 0x...)
    local count=$(grep -cE '^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{9}(Z|[+-][0-9]{2}:[0-9]{2})) \| 0x[A-F0-9]{8}$' "$PRIMARY_LOG" || 0)

    if [ "$count" -ge "$expected_count_min" ] && [ "$count" -le "$expected_count_max" ]; then
        echo "PASS: $desc - Count: $count (expected $expected_count_min-$expected_count_max)"
        head -3 "$PRIMARY_LOG"  # Show sample
    else
        echo "FAIL: $desc - Count: $count (expected $expected_count_min-$expected_count_max)"
        cat "$PRIMARY_LOG"
        return 1
    fi
}

# Test 1: Default interval (5s) - expect ~1-2 entries in 8s
run_interval_test 5 1 2 "default"

# Test 2: Short interval 1s - expect ~6-8 entries
run_interval_test 1 6 8 "short (1s)"

# Test 3: Medium 3s - expect ~2-3 entries
run_interval_test 3 2 3 "medium (3s)"

# Test 4: Invalid 0 - expect error
run_interval_test "error" 0 0 "invalid (0)"

echo "All interval tests passed!"
