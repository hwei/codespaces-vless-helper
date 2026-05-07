## Purpose
Provide a Codespaces-hosted helper page that displays current VLESS connection details, client configuration snippets, routing guidance, and security warnings.

## Requirements

### Requirement: Helper page starts with the Codespace
The system SHALL start a connection helper web server during Codespace startup.

#### Scenario: Codespace start
- **WHEN** the Codespace starts
- **THEN** the helper web server starts on its configured local port

#### Scenario: Helper already running
- **WHEN** startup automation runs while the helper server is already listening
- **THEN** the automation does not start duplicate helper server processes

### Requirement: Helper page displays current runtime facts
The helper page SHALL display the current Codespace runtime values needed to configure a client.

#### Scenario: Runtime facts are available
- **WHEN** a user opens the helper page
- **THEN** the page displays the current internal IPv4 address, VLESS service port, WebSocket path, UUID, and observed helper page host

#### Scenario: Forwarded VLESS host can be derived
- **WHEN** the helper can derive the forwarded VLESS host from the observed request or Codespaces environment
- **THEN** the page displays the derived VLESS host and full client connection address

#### Scenario: Forwarded VLESS host cannot be derived
- **WHEN** the helper cannot confidently derive the forwarded VLESS host
- **THEN** the page displays a clear instruction for locating or entering the forwarded VLESS port URL manually

### Requirement: Helper page provides client configuration outputs
The helper page SHALL provide copyable client configuration outputs for the supported client formats.

#### Scenario: Clash Verge or Mihomo output
- **WHEN** the helper page renders client configuration
- **THEN** it includes a Clash Verge/Mihomo-compatible VLESS WebSocket node using TLS to the GitHub forwarded host

#### Scenario: VLESS URL output
- **WHEN** the helper page renders client configuration
- **THEN** it includes a VLESS URL containing the current host, UUID, WebSocket path, TLS setting, host header, and SNI value

#### Scenario: Xray client output
- **WHEN** the helper page renders client configuration
- **THEN** it includes an Xray JSON client outbound example for the current VLESS WebSocket endpoint

### Requirement: Helper page provides routing guidance
The helper page SHALL provide rule guidance for routing only the current Codespace internal IP through the VLESS node.

#### Scenario: Internal IP is detected
- **WHEN** the helper detects the Codespace internal IPv4 address
- **THEN** the page displays a rule example equivalent to `IP-CIDR,<internal-ip>/32,<node-name>`

#### Scenario: Internal IP changes
- **WHEN** the Codespace internal IPv4 address changes between sessions
- **THEN** the helper page displays the new address without requiring code changes

### Requirement: Helper page communicates security constraints
The helper page MUST communicate that public forwarded URLs and UUID-bearing configuration snippets are sensitive.

#### Scenario: Public helper page is opened
- **WHEN** the helper page is opened through a public forwarded URL
- **THEN** the page warns that the displayed node configuration should not be shared or committed

#### Scenario: UUID rotation is not automated
- **WHEN** the helper page displays the persisted UUID
- **THEN** the page explains that UUID rotation will invalidate existing client configurations
