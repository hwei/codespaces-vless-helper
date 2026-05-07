## Context

The current proof of concept runs Xray manually inside a GitHub Codespace and exposes a VLESS WebSocket inbound through GitHub's forwarded HTTPS domain. Clash Verge/Mihomo can connect when the client uses TLS to the GitHub forwarding endpoint, while Xray itself still receives plain HTTP WebSocket traffic inside the Codespace.

The working path is:

```text
Client
  -> VLESS + WebSocket + TLS
  -> GitHub Codespaces forwarded HTTPS host
  -> VLESS + WebSocket + plain HTTP inside Codespace
  -> internal Codespace service such as http://10.0.0.24:8080/
```

The fragile parts are service startup, dynamic internal IPs, dynamic forwarded hosts, public port visibility, and user-facing configuration generation.

## Goals / Non-Goals

**Goals:**

- Make the VLESS service reproducible across Codespace starts.
- Start both Xray and the connection helper automatically when the Codespace starts.
- Expose current runtime facts through a helper page: internal IP, forwarded host, UUID, port, WebSocket path, and client configuration snippets.
- Attempt to set required forwarded ports to public visibility automatically.
- Clearly document the difference between external TLS and internal plain WebSocket.
- Keep the first implementation compatible with Clash Verge/Mihomo using VLESS over WebSocket.

**Non-Goals:**

- Automatically patching a user's subscription script or remote subscription source.
- Providing a production-grade zero-trust access control system.
- Replacing GitHub Codespaces port forwarding.
- Migrating to XHTTP in the first implementation.
- Supporting every possible proxy client in the initial release.

## Decisions

### Use Xray with VLESS over WebSocket for the first implementation

Use the transport that was already validated end to end with Clash Verge/Mihomo. Xray currently warns that WebSocket transport is deprecated, but WebSocket remains the most practical first transport because client support is broad and the experiment has already proven the path.

Alternative considered: XHTTP. It is the likely future transport to evaluate, but client support and configuration compatibility need separate validation before making it the default.

### Use devcontainer lifecycle hooks for automation

Install and initialize required assets during Codespace creation, then start runtime services during each Codespace start. The expected shape is:

```text
.devcontainer/
  -> install/setup scripts for Xray and helper dependencies
  -> postCreateCommand for initial configuration
  -> postStartCommand for starting Xray and the helper server
```

The startup path should be idempotent so repeated starts do not corrupt existing UUIDs or configuration.

Alternative considered: relying on manual terminal commands. This is acceptable for experimentation but does not meet the stabilization goal.

### Generate runtime configuration from current environment

Do not hard-code the Codespace internal IP or forwarded host. The helper should discover the current internal IPv4 address at runtime and derive or display the current forwarded host based on request information and known Codespaces environment variables.

When host derivation is uncertain, the helper should display the observed helper page host and explain how to verify the corresponding VLESS forwarded URL.

### Use best-effort public port visibility automation

The startup process should try to run GitHub CLI commands equivalent to setting the VLESS and helper ports public. If GitHub CLI authentication, organization policy, or Codespaces policy blocks the change, the helper page and startup logs should explain the manual fallback.

Alternative considered: requiring manual public visibility setup only. This is simpler but creates a repeated setup burden and is easy to forget.

### Keep UUID stable by default and support later rotation

The first implementation should persist a generated UUID across restarts to avoid breaking clients on every Codespace start. UUID rotation should be designed as a follow-up capability or optional command because it changes all client configurations.

## Risks / Trade-offs

- Public forwarded URLs behave like bearer-style entry points: anyone with the URL can attempt to connect. Mitigation: require the VLESS UUID, explain leakage risks, avoid committing generated secrets, and consider a rotation command.
- GitHub organization policy may prevent public port visibility. Mitigation: make port visibility best effort and provide clear manual instructions.
- Codespaces forwarded host derivation may vary. Mitigation: display observed host data and allow manual verification.
- WebSocket transport may be removed from Xray in the future. Mitigation: keep XHTTP as a tracked future investigation, not an MVP dependency.
- The helper page may expose sensitive node information if made public. Mitigation: document that the helper page should be treated as sensitive and consider showing warnings before revealing full config snippets.

## Migration Plan

1. Add the automation and helper page alongside the existing manual files.
2. Validate a fresh Codespace start creates or reuses Xray configuration and starts both services.
3. Validate the VLESS forwarded port and helper forwarded port are public or show actionable fallback instructions.
4. Validate generated Clash Verge/Mihomo configuration reaches an internal test HTTP service.
5. Keep manual commands documented as rollback for users who need to start Xray directly.

## Open Questions

- Which Codespaces environment variables are always available for deriving forwarded domains?
- Should the helper page require a local token before showing UUID-bearing configuration snippets?
- Which additional client formats should be included in the first release beyond Clash Verge/Mihomo and Xray JSON?
- Should UUID rotation be part of the initial implementation or a separate follow-up change?
