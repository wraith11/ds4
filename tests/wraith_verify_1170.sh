#!/bin/bash
# Verify the KV disk-cache "evict protection" change (upstream antirez/ds4 PR #1170)
# in the ds4 fork.  It protects the checkpoint that the *next* request will load
# from being evicted when the server stores the outgoing session's snapshot.
#
# Usage: bash tests/wraith_verify_1170.sh
# Output is also written to /tmp/ds4_verify_1170.log so it can be sent back.
set -u
cd "$(dirname "$0")/.."

LOG=/tmp/ds4_verify_1170.log
: > "$LOG"

echo "=== [1/2] Building ds4_test (Metal build) ==="
# A clean build is safest; if you have a warm tree you may drop "make clean".
make clean >> "$LOG" 2>&1 || true
make -j4 ds4_test >> "$LOG" 2>&1 || {
    echo "BUILD FAILED — full log in $LOG (tail below)"
    tail -n 40 "$LOG"
    exit 1
}

echo "=== [2/2] Running server unit tests (includes the 3 new evict-protection tests) ==="
./ds4_test --server >> "$LOG" 2>&1

echo "=== Result ==="
if grep -q "ds4 tests: ok" "$LOG"; then
    echo "PASS: server unit tests passed (ds4 tests: ok)."
    grep -E "server: (OK|ERR)" "$LOG" || true
else
    echo "CHECK/FAIL — inspect $LOG"
    grep -E "server: (OK|ERR)|ds4 tests:" "$LOG" || true
    tail -n 40 "$LOG"
    exit 1
fi
echo
echo "Full log saved to: $LOG"
