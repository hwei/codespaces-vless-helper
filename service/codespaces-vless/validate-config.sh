#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=service/codespaces-vless/defaults.sh
source "${SCRIPT_DIR}/defaults.sh"

"${SCRIPT_DIR}/setup.sh"
"${CODESPACES_VLESS_XRAY_BIN}" run -test -config "${CODESPACES_VLESS_XRAY_CONFIG}"
