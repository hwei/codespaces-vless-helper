#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=service/codespaces-vless/defaults.sh
source "${SCRIPT_DIR}/defaults.sh"

log() {
  printf '[codespaces-vless setup] %s\n' "$*"
}

detect_xray_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  if [[ "${os}" != "Linux" ]]; then
    printf 'unsupported'
    return
  fi

  case "${arch}" in
    x86_64|amd64) printf 'Xray-linux-64.zip' ;;
    aarch64|arm64) printf 'Xray-linux-arm64-v8a.zip' ;;
    *) printf 'unsupported' ;;
  esac
}

install_xray() {
  if [[ -x "${CODESPACES_VLESS_XRAY_BIN}" ]] && "${CODESPACES_VLESS_XRAY_BIN}" version >/dev/null 2>&1; then
    log "Xray already installed at ${CODESPACES_VLESS_XRAY_BIN}"
    return
  fi

  local asset zip url
  asset="$(detect_xray_asset)"
  if [[ "${asset}" == "unsupported" ]]; then
    log "unsupported architecture: $(uname -s) $(uname -m)"
    return 1
  fi

  command -v curl >/dev/null 2>&1 || { log "curl is required to download Xray"; return 1; }
  command -v unzip >/dev/null 2>&1 || { log "unzip is required to extract Xray"; return 1; }

  zip="${CODESPACES_VLESS_DOWNLOAD_DIR}/${asset}"
  url="https://github.com/XTLS/Xray-core/releases/download/${CODESPACES_VLESS_XRAY_VERSION}/${asset}"

  log "downloading ${url}"
  curl -fsSL "${url}" -o "${zip}"
  unzip -q -o "${zip}" -d "${CODESPACES_VLESS_BIN_DIR}"
  chmod 0755 "${CODESPACES_VLESS_XRAY_BIN}"
  "${CODESPACES_VLESS_XRAY_BIN}" version | head -n 1
}

read_or_create_uuid() {
  if [[ -s "${CODESPACES_VLESS_UUID_FILE}" ]]; then
    tr -d '\n\r[:space:]' < "${CODESPACES_VLESS_UUID_FILE}"
    return
  fi

  local uuid
  if [[ -x "${CODESPACES_VLESS_XRAY_BIN}" ]]; then
    uuid="$("${CODESPACES_VLESS_XRAY_BIN}" uuid)"
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    uuid="$(cat /proc/sys/kernel/random/uuid)"
  else
    uuid="$(uuidgen)"
  fi

  printf '%s\n' "${uuid}" > "${CODESPACES_VLESS_UUID_FILE}"
  chmod 0600 "${CODESPACES_VLESS_UUID_FILE}"
  printf '%s' "${uuid}"
}

write_xray_config() {
  local uuid
  uuid="$(read_or_create_uuid)"

  cat > "${CODESPACES_VLESS_XRAY_CONFIG}" <<JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "codespaces-vless-ws",
      "listen": "0.0.0.0",
      "port": ${CODESPACES_VLESS_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "email": "${CODESPACES_VLESS_NODE_NAME}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "${CODESPACES_VLESS_WS_PATH}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
JSON
  chmod 0600 "${CODESPACES_VLESS_XRAY_CONFIG}"
  log "wrote ${CODESPACES_VLESS_XRAY_CONFIG}"
}

main() {
  codespaces_vless_ensure_dirs
  install_xray
  write_xray_config
}

main "$@"
