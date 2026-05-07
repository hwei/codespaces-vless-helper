## Why

The experiment proved that a GitHub Codespace can expose selected internal services through a VLESS over WebSocket tunnel, but the current setup is manual, session-specific, and easy to misconfigure. We need a repeatable local workflow that starts the tunnel services automatically and gives users a single place to retrieve current connection details.

## What Changes

- Add a Codespaces-oriented VLESS service setup that installs, initializes, and starts Xray with a VLESS WebSocket inbound on a fixed internal port.
- Add startup automation for the VLESS service and a separate connection helper web server whenever the Codespace starts.
- Add a connection helper page that displays the current Codespace internal IP, forwarded host information, VLESS node details, client configuration snippets, and routing-rule guidance.
- Document manual public port visibility setup for the VLESS and helper ports in the Codespaces Ports panel.
- Document the transport and security model: GitHub terminates external HTTPS, while the Xray inbound remains plain HTTP WebSocket inside the Codespace.
- Keep subscription patching out of scope; users can apply the displayed node and rule information to their own subscription workflow.

## Capabilities

### New Capabilities

- `codespaces-vless-service`: Provides the Xray-based VLESS WebSocket service lifecycle for Codespaces, including installation, configuration, startup, and port exposure behavior.
- `connection-helper-page`: Provides a browser-accessible helper page that reports current runtime connection information and generates client configuration guidance.

### Modified Capabilities

- None.

## Impact

- Adds devcontainer lifecycle configuration or equivalent startup scripts for installing and starting local services.
- Adds an Xray configuration generation path with UUID management and WebSocket transport settings.
- Adds a lightweight local web server for connection assistance.
- Adds generated configuration outputs for Clash Verge/Mihomo, Xray clients, and possibly other clients where support is straightforward.
- Relies on Codespaces forwarded ports and manual public visibility setup in the Ports panel.
- Introduces security documentation around public forwarded URLs, UUID handling, and optional UUID rotation.
