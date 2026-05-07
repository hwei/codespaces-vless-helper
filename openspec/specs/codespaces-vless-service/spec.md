## Purpose
Provide reproducible setup, configuration, and startup automation for a VLESS over WebSocket service running inside GitHub Codespaces.

## Requirements

### Requirement: Xray installation is reproducible
The system SHALL provide a reproducible setup path that installs an Xray binary suitable for the Codespace architecture without requiring manual download steps from the user.

#### Scenario: Fresh Codespace setup
- **WHEN** a new Codespace is created for the project
- **THEN** the setup process installs Xray or confirms an existing compatible Xray binary is available

#### Scenario: Repeated setup
- **WHEN** the setup process runs more than once
- **THEN** the process preserves the existing valid installation and completes without corrupting local configuration

### Requirement: VLESS service configuration is generated
The system SHALL generate an Xray server configuration for VLESS over WebSocket on a fixed internal port with no TLS on the Xray inbound.

#### Scenario: Configuration generation
- **WHEN** Xray configuration is initialized
- **THEN** the configuration includes a VLESS inbound, WebSocket transport, `security: none`, a stable WebSocket path, and a persisted UUID

#### Scenario: Existing UUID reuse
- **WHEN** configuration already contains a valid UUID
- **THEN** the system reuses that UUID unless the user explicitly rotates it

### Requirement: Services start automatically with Codespace lifecycle
The system SHALL start the VLESS service during Codespace startup without requiring the user to run a manual Xray command.

#### Scenario: Codespace start
- **WHEN** the Codespace starts
- **THEN** the Xray service starts with the generated VLESS WebSocket configuration

#### Scenario: Service already running
- **WHEN** startup automation runs while Xray is already listening on the configured port
- **THEN** the automation does not start duplicate Xray processes

### Requirement: Forwarded port visibility is manual
The system SHALL require users to set the VLESS service port and connection helper port to public visibility manually in the Codespaces Ports panel.

#### Scenario: Startup avoids port visibility mutation
- **WHEN** startup automation runs
- **THEN** it does not call GitHub CLI to change forwarded port visibility

#### Scenario: Manual public visibility
- **WHEN** a user needs external client access
- **THEN** they set the configured ports to public in the Codespaces Ports panel

### Requirement: Transport model is explicit
The system MUST preserve plain HTTP WebSocket between GitHub's forwarding layer and the Xray inbound while requiring clients to use TLS when connecting through the GitHub forwarded HTTPS host.

#### Scenario: Client configuration through GitHub forwarding
- **WHEN** a client configuration is generated for the forwarded Codespaces host
- **THEN** the client configuration uses TLS externally and WebSocket transport to the configured path

#### Scenario: Xray inbound configuration
- **WHEN** the Xray server configuration is inspected
- **THEN** the inbound transport uses WebSocket with no Xray-managed TLS
