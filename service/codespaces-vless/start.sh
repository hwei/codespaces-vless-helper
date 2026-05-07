#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=service/codespaces-vless/defaults.sh
source "${SCRIPT_DIR}/defaults.sh"

log() {
  codespaces_vless_ensure_dirs
  printf '[codespaces-vless start] %s\n' "$*" | tee -a "${CODESPACES_VLESS_STARTUP_LOG}"
}

time_stage() {
  local label="$1"
  shift

  local started finished elapsed
  started="${SECONDS}"
  "$@"
  finished="${SECONDS}"
  elapsed=$((finished - started))
  log "${label} completed in ${elapsed}s"
}

port_listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    if ss -ltn "( sport = :${port} )" 2>/dev/null | tail -n +2 | grep -q .; then
      return 0
    fi
  fi
  timeout 1 bash -c ":</dev/tcp/127.0.0.1/${port}" >/dev/null 2>&1
}

pid_running() {
  local pid_file="$1"
  [[ -s "${pid_file}" ]] && kill -0 "$(cat "${pid_file}")" >/dev/null 2>&1
}

ensure_setup() {
  if [[ -x "${CODESPACES_VLESS_XRAY_BIN}" ]] && [[ -s "${CODESPACES_VLESS_XRAY_CONFIG}" ]]; then
    log "Xray binary and config already exist; skipping setup"
    return
  fi

  log "Xray binary or config is missing; running setup"
  "${SCRIPT_DIR}/setup.sh"
}

start_xray() {
  if port_listening "${CODESPACES_VLESS_PORT}" || pid_running "${CODESPACES_VLESS_XRAY_PID}"; then
    log "Xray is already running on port ${CODESPACES_VLESS_PORT}"
    return
  fi

  log "starting Xray on port ${CODESPACES_VLESS_PORT}"
  nohup "${CODESPACES_VLESS_XRAY_BIN}" run -config "${CODESPACES_VLESS_XRAY_CONFIG}" > "${CODESPACES_VLESS_XRAY_LOG}" 2>&1 &
  printf '%s\n' "$!" > "${CODESPACES_VLESS_XRAY_PID}"
  sleep 1

  if ! port_listening "${CODESPACES_VLESS_PORT}"; then
    log "Xray did not start; inspect ${CODESPACES_VLESS_XRAY_LOG}"
    return 1
  fi
}

start_helper() {
  if port_listening "${CODESPACES_VLESS_HELPER_PORT}" || pid_running "${CODESPACES_VLESS_HELPER_PID}"; then
    log "helper server is already running on port ${CODESPACES_VLESS_HELPER_PORT}"
    return
  fi

  log "starting helper page on port ${CODESPACES_VLESS_HELPER_PORT}"
  nohup node "${SCRIPT_DIR}/helper-server.js" > "${CODESPACES_VLESS_HELPER_LOG}" 2>&1 &
  printf '%s\n' "$!" > "${CODESPACES_VLESS_HELPER_PID}"
  sleep 1

  if ! port_listening "${CODESPACES_VLESS_HELPER_PORT}"; then
    log "helper server did not start; inspect ${CODESPACES_VLESS_HELPER_LOG}"
    return 1
  fi
}

main() {
  local started finished elapsed
  started="${SECONDS}"

  log "startup timing begins"
  time_stage "setup check" ensure_setup
  time_stage "Xray startup" start_xray
  time_stage "helper startup" start_helper

  finished="${SECONDS}"
  elapsed=$((finished - started))
  log "startup completed in ${elapsed}s"
  log "helper page: forward/open port ${CODESPACES_VLESS_HELPER_PORT}; VLESS service port: ${CODESPACES_VLESS_PORT}"
}

main "$@"
