# Alfa Security Model

## Authentication

- Local password protection for settings, sensitive actions, and uninstall flows
- Device pairing with cryptographically generated codes
- Server authentication via tokens and HTTPS

## Anti-tampering

- Multi-process watchdog model
- Core engine restart if termination is detected
- Debugger detection and self-defense hooks planned

## Data protections

- Strong password hashing using Argon2 or bcrypt semantics
- Salted, memory-hard storage for local credentials
- Signed payloads for IPC and remote commands
