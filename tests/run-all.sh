#!/bin/bash
# run-all.sh - discover and run every hermetic script test in the repo.
#
# A "test" is any executable-or-not `test-*.sh` living under a `tests/`
# directory anywhere in the tree (e.g. skills/.../scripts/tests/,
# templates/statusline/tests/). Each test file is a self-contained bash
# program that exits 0 on success and non-zero on the first failure.
#
# This runner is the single entrypoint for local runs and CI:
#   bash tests/run-all.sh
#   make test
#
# Exit: 0 = every test file passed, 1 = at least one failed (or none found).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Collect test files deterministically (sorted), skipping this runner and .git.
# while-read (not mapfile) so the runner works on bash 3.2 (default macOS bash).
TESTS=()
while IFS= read -r _t; do
    TESTS+=("$_t")
done < <(
    find "$REPO_ROOT" \
        -path "$REPO_ROOT/.git" -prune -o \
        -type f -path '*/tests/test-*.sh' -print | sort
)

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "FAIL: no test files found (expected */tests/test-*.sh)" >&2
    exit 1
fi

TOTAL=${#TESTS[@]}
FAILED_FILES=()

echo "Running ${TOTAL} test file(s)"
echo "========================================"

for test in "${TESTS[@]}"; do
    rel="${test#"$REPO_ROOT"/}"
    echo ""
    echo ">>> ${rel}"
    if bash "$test"; then
        :
    else
        FAILED_FILES+=("$rel")
    fi
done

echo ""
echo "========================================"
if [[ ${#FAILED_FILES[@]} -eq 0 ]]; then
    echo "SUITE PASS: ${TOTAL}/${TOTAL} test file(s) passed."
    exit 0
fi

echo "SUITE FAIL: ${#FAILED_FILES[@]}/${TOTAL} test file(s) failed:" >&2
for f in "${FAILED_FILES[@]}"; do
    echo "  - ${f}" >&2
done
exit 1
