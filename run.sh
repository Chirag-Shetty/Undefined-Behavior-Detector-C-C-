#!/usr/bin/env bash
# =============================================================================
# run.sh — run the UB Time Bomb Detector
# =============================================================================
# Usage examples:
#   ./run.sh testcases/signed_overflow.c          # single file
#   ./run.sh testcases/                            # whole directory
#   ./run.sh --all-cve                             # all CVE test cases
#   ./run.sh --all-cve --html                      # + HTML report
#   ./run.sh testcases/signed_overflow.c --verbose # detailed evidence
#   ./run.sh --help                                # show all flags
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

exec python3 main.py "$@"
