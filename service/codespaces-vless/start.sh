#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=service/codespaces-vless/defaults.sh
source "${SCRIPT_DIR}/defaults.sh"

log() {
  codespaces_vless_ensure_dirs
  printf '[codespaces-vless start] %s\n' "$*" | tee -a "${CODESPACES_VLESS_STARTUP_LOG}"
}

port_listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :${port} )" | tail -n +2 | grep -q .
    return
  fi
  timeout 1 bash -c ":</dev/tcp/127.0.0.1/${port}" >/dev/null 2>&1
}

pid_running() {
  local pid_file="$1"
  [[ -s "${pid_file}" ]] && kill -0 "$(cat "${pid_file}")" >/dev/null 2>&1
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

set_public_port() {
  local port="$1"

  if ! command -v gh >/dev/null 2>&1; then
    log "GitHub CLI is unavailable; manually set port ${port} visibility to Public in the Codespaces Ports panel."
    return
  fi

  if ! gh auth status >/dev/null 2>&1; then
    log "GitHub CLI is not authenticated; run 'gh auth login' or manually set port ${port} visibility to Public in the Codespaces Ports panel."
    return
  fi

  if [[ -n "${CODESPACE_NAME:-}" ]]; then
    if gh codespace ports visibility "${port}:public" -c "${CODESPACE_NAME}" >/dev/null 2>&1; then
      log "set port ${port} visibility to public"
      return
    fi
  else
    if gh codespace ports visibility "${port}:public" >/dev/null 2>&1; then
      log "set port ${port} visibility to public"
      return
    fi
  fi

  log "could not set port ${port} public automatically; use the Codespaces Ports panel or run: gh codespace ports visibility ${port}:public -c \"${CODESPACE_NAME:-<codespace-name>}\""
}

main() {
  "${SCRIPT_DIR}/setup.sh"
  start_xray
  start_helper
  set_public_port "${CODESPACES_VLESS_PORT}"
  set_public_port "${CODESPACES_VLESS_HELPER_PORT}"
  log "helper page: forward/open port ${CODESPACES_VLESS_HELPER_PORT}; VLESS service port: ${CODESPACES_VLESS_PORT}"
}

main "$@"
