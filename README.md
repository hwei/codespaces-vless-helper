# Codespaces VLESS Helper

This repository sets up an Xray VLESS over WebSocket service inside a GitHub Codespace and serves a local helper page with current client configuration snippets.

## Codespace Startup

Codespaces lifecycle hooks run:

```bash
bash service/codespaces-vless/setup.sh
bash service/codespaces-vless/start.sh
```

The setup script installs Xray for the current Linux architecture, creates a stable UUID, and writes the generated Xray server config under `.local/codespaces-vless/`. The startup script starts Xray on port `10086` and starts the helper page on port `18080`.

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

## Public Ports

Set forwarded ports `10086` and `18080` to **Public** manually in the Codespaces Ports panel. The VLESS client snippets require the VLESS service port `10086` to be public. The helper page also exposes UUID-bearing snippets, so treat the helper URL as sensitive.

## Startup Timing

Setup and startup scripts log phase timings to help diagnose slow Codespace creation or startup. `setup.sh` reports directory setup, Xray install checks, and config generation. `start.sh` reports setup checks, Xray startup, helper startup, and total startup time.

```bash
tail -n 80 .local/codespaces-vless/logs/setup.log
tail -n 80 .local/codespaces-vless/logs/startup.log
```

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
