# Alfa Architecture

## Module overview

- `core/` — enforcement engine with the watchdog and IPC boundary
- `app/` — desktop orchestration and user interface
- `cli/` — developer console for pairing, policies, and local state
- `server/` — ASP.NET Core control plane for device and policy management
- `web/` — C# Blazor Server dashboard for remote administration
- `shared/` — cross-module models and protocol definitions

## Data flow

1. `cli` and `app` generate local pairing and enforcement actions.
2. `app` communicates with `core` via IPC and command validation.
3. `server` exposes device and policy endpoints for cloud sync and remote orchestration.
4. `core` hosts a local secure command channel on `127.0.0.1:4712` and persists policy state and audit telemetry in `core_state.db` using SQLite.
5. Local policy enforcement and telemetry are managed locally in the C++/C# stack.

## Enforcement model

- Priority-based policy evaluation
- Rule types: always allow, always block, time restrictions, usage quota, password lock
- Local cache and sync support with remote control plane
