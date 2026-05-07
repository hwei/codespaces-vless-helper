## ADDED Requirements

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

### Requirement: Forwarded ports are made public when possible
The system SHALL attempt to set the VLESS service port and connection helper port to public visibility using available GitHub Codespaces tooling.

#### Scenario: Public visibility succeeds
- **WHEN** GitHub CLI authentication and policy allow public port visibility
- **THEN** the startup process sets the configured ports to public visibility

#### Scenario: Public visibility is blocked
- **WHEN** GitHub CLI authentication, organization policy, or Codespaces policy prevents public visibility
- **THEN** the system reports a clear fallback instruction for manually setting the ports to public

### Requirement: Transport model is explicit
The system MUST preserve plain HTTP WebSocket between GitHub's forwarding layer and the Xray inbound while requiring clients to use TLS when connecting through the GitHub forwarded HTTPS host.

#### Scenario: Client configuration through GitHub forwarding
- **WHEN** a client configuration is generated for the forwarded Codespaces host
- **THEN** the client configuration uses TLS externally and WebSocket transport to the configured path

#### Scenario: Xray inbound configuration
- **WHEN** the Xray server configuration is inspected
- **THEN** the inbound transport uses WebSocket with no Xray-managed TLS
