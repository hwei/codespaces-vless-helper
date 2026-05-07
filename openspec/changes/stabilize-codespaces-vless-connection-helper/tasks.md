## 1. Project Structure and Runtime Defaults

- [ ] 1.1 Define the service directory layout for Xray assets, generated config, helper server code, logs, and runtime state.
- [ ] 1.2 Add a gitignore policy for downloaded binaries, generated UUID/config files, logs, and other local secrets.
- [ ] 1.3 Define default ports, node name, WebSocket path, and state file locations in one reusable configuration module or script.
- [ ] 1.4 Move existing experimental artifacts that are not part of the final design into a temporary archive directory outside the tracked project scope.

## 2. Xray Installation and Configuration

- [ ] 2.1 Add an idempotent setup script that installs or verifies an Xray binary compatible with the Codespace architecture.
- [ ] 2.2 Add an idempotent configuration generator for VLESS over WebSocket with an internal plain HTTP WebSocket inbound.
- [ ] 2.3 Persist the generated UUID across restarts and reuse it unless explicit rotation is requested.
- [ ] 2.4 Add a manual validation command or script that verifies the generated Xray configuration can start.

## 3. Codespaces Startup Automation

- [ ] 3.1 Add devcontainer lifecycle configuration to run setup during Codespace creation.
- [ ] 3.2 Add startup automation that starts Xray if it is not already running.
- [ ] 3.3 Add startup automation that starts the connection helper web server if it is not already running.
- [ ] 3.4 Add best-effort GitHub CLI port visibility automation for the VLESS service port and helper page port.
- [ ] 3.5 Log actionable fallback instructions when public port visibility cannot be set automatically.

## 4. Connection Helper Page

- [ ] 4.1 Implement runtime discovery for the current internal IPv4 address.
- [ ] 4.2 Implement forwarded host discovery using request host data and available Codespaces environment variables.
- [ ] 4.3 Render current VLESS node details, including host, port, UUID, WebSocket path, TLS expectation, and node name.
- [ ] 4.4 Render copyable VLESS URL output for the current endpoint.
- [ ] 4.5 Render copyable Clash Verge/Mihomo YAML node output for the current endpoint.
- [ ] 4.6 Render copyable Xray JSON client outbound output for the current endpoint.
- [ ] 4.7 Render routing-rule guidance using the current internal IP as a `/32` target.
- [ ] 4.8 Render security guidance for public forwarded URLs, UUID handling, and configuration leakage.

## 5. Verification

- [ ] 5.1 Verify a fresh Codespace setup installs Xray, creates configuration, and starts the VLESS service.
- [ ] 5.2 Verify the helper page starts automatically and displays the current internal IP and generated node details.
- [ ] 5.3 Verify public port visibility automation succeeds when allowed or produces clear fallback instructions when blocked.
- [ ] 5.4 Verify a generated Clash Verge/Mihomo configuration can route traffic to a local HTTP test service through the VLESS endpoint.
- [ ] 5.5 Verify repeated startup does not create duplicate Xray or helper server processes.
- [ ] 5.6 Verify generated secrets and downloaded binaries are not tracked by Git.
- [ ] 5.7 Verify the Git working tree contains only source files, OpenSpec artifacts, documentation, and intentional configuration templates.

## 6. Documentation

- [ ] 6.1 Document how to open the connection helper page after Codespace startup.
- [ ] 6.2 Document the external TLS versus internal plain WebSocket transport model.
- [ ] 6.3 Document how to manually set forwarded ports to public when automation fails.
- [ ] 6.4 Document current client support and record XHTTP as a future investigation item.
