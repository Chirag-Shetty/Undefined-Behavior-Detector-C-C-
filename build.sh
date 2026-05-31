#!/usr/bin/env bash
# =============================================================================
# build.sh — verify prerequisites for UB Time Bomb Detector
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

echo "========================================================"
echo " UB Time Bomb Detector — Build / Prerequisite Check"
echo "========================================================"
echo ""

# ── Python ────────────────────────────────────────────────────────────────────
echo "Checking Python..."
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    if [[ "$PY_MAJOR" -ge 3 && "$PY_MINOR" -ge 10 ]]; then
        ok "Python $PY_VER found at $(command -v python3)"
    else
        fail "Python 3.10+ required, found $PY_VER"
    fi
else
    fail "python3 not found in PATH"
fi

# ── Clang ────────────────────────────────────────────────────────────────────
echo ""
echo "Checking Clang..."
CLANG_BIN=""
for candidate in clang-18 clang-17 clang-16 clang; do
    if command -v "$candidate" &>/dev/null; then
        CLANG_BIN="$candidate"
        CLANG_VER=$("$candidate" --version | head -1)
        ok "$candidate found — $CLANG_VER"
        break
    fi
done
if [[ -z "$CLANG_BIN" ]]; then
    fail "No clang binary found. Install with: sudo apt install clang-18"
fi

# ── No external Python packages needed ────────────────────────────────────────
echo ""
echo "Checking Python stdlib modules..."
python3 -c "import re, subprocess, pathlib, dataclasses, enum, textwrap, html" \
    && ok "All required stdlib modules available"

# ── Unit tests ───────────────────────────────────────────────────────────────
echo ""
echo "Running unit tests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if python3 -m unittest discover -s tests -q 2>&1; then
    TEST_COUNT=$(python3 -m unittest discover -s tests -v 2>&1 | grep -c "^test_" || true)
    ok "Unit tests passed"
else
    fail "Unit tests failed — see above for details"
fi

echo ""
echo "========================================================"
echo -e "${GREEN} All checks passed.${NC} Run the detector with:"
echo "   ./run.sh testcases/signed_overflow.c"
echo "   ./run.sh --all-cve"
echo "========================================================"
