# Codespaces VLESS Helper

This repository sets up an Xray VLESS over WebSocket service inside a GitHub Codespace and serves a local helper page with current client configuration snippets.

## Codespace Startup

Codespaces lifecycle hooks run:

```bash
bash service/codespaces-vless/setup.sh
bash service/codespaces-vless/start.sh
```

The setup script installs Xray for the current Linux architecture, creates a stable UUID, and writes the generated Xray server config under `.local/codespaces-vless/`. The startup script starts Xray on port `10086`, starts the helper page on port `18080`, and tries to set both forwarded ports to public visibility.

To open the helper page, open the Codespaces **Ports** panel and open forwarded port `18080`. The page shows the current internal IPv4 address, observed helper host, derived VLESS forwarded host, UUID, WebSocket path, VLESS URL, Clash Verge/Mihomo YAML, Xray client JSON, and a routing rule such as:

```text
IP-CIDR,<internal-ip>/32,codespace-vless
```

## Transport Model

External clients connect to GitHub's forwarded HTTPS host on port `443` using TLS:

```text
Client -> VLESS + WebSocket + TLS -> *.app.github.dev:443
```

Inside the Codespace, GitHub forwards plain HTTP WebSocket traffic to Xray:

```text
GitHub forwarding -> VLESS + WebSocket + security: none -> Xray on port 10086
```

Do not enable Xray-managed TLS for this inbound unless the forwarding model changes.

## Public Port Fallback

Startup runs a best-effort command equivalent to:

```bash
gh codespace ports visibility 10086:public -c "$CODESPACE_NAME"
gh codespace ports visibility 18080:public -c "$CODESPACE_NAME"
```

If GitHub CLI authentication, organization policy, or Codespaces policy blocks automation, set the ports to **Public** manually in the Codespaces Ports panel. The VLESS client snippets require the VLESS service port `10086` to be public. The helper page also exposes UUID-bearing snippets, so treat the helper URL as sensitive.

## Validation

Run this after setup to verify that the generated Xray config can start:

```bash
bash service/codespaces-vless/validate-config.sh
```

Run startup repeatedly to verify it does not create duplicate Xray or helper processes:

```bash
bash service/codespaces-vless/start.sh
bash service/codespaces-vless/start.sh
```

Generated binaries, UUIDs, configs, logs, PID files, and downloads are ignored by Git under `.local/codespaces-vless/`.

## Client Support

The first implementation targets Clash Verge/Mihomo-compatible VLESS over WebSocket and Xray JSON outbound clients. XHTTP remains a future investigation because client compatibility needs separate validation before it can replace WebSocket as the default.
