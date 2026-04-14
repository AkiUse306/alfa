# Alfa

Alfa is an enterprise-grade, multi-layer system control and protection platform built to enforce access control, productivity policies, and endpoint security across devices. It includes a modern C# Blazor dashboard, C# desktop orchestration, C++ core enforcement, and a secure backend control plane. The C++ core hosts a local secure IPC channel with HMAC-signed commands and persists policy state in SQLite.

## What is Alfa?

Alfa combines:

- A low-level protection engine written in C++
- A desktop orchestration app using C# / .NET
- A developer CLI for pairing and enforcement actions
- A cloud control plane backend using C# / ASP.NET Core

## Repository layout

- `core/` — C++ protection engine with IPC and enforcement stubs
- `app/` — Desktop orchestration app using .NET and WPF
- `cli/` — Command-line interface for status, pairing, and lock actions
- `server/` — ASP.NET Core backend for device and policy management
- `web/` — C# Blazor Server dashboard for remote administration
- `shared/` — Shared contracts, models, and protocol definitions
- `docs/` — Architecture and security documentation

> The repository is linked to GitHub Pages at `https://akiuse306.github.io/alfa` for easy public access.

## Getting started

### Prerequisites

- .NET 10 SDK
- CMake

### Build all modules

```bash
./build.sh
```

### Run modules

```bash
# Build and run core engine
cd core && cmake -S . -B build && cmake --build build

# Run server backend
cd server && dotnet run

# Run Blazor web dashboard
cd web && dotnet run

# Run CLI
cd cli && dotnet run -- --status

# Build desktop app (Windows only)
cd app/desktop && dotnet build -c Release
```

### Features

- Local core IPC with HMAC-signed commands (`STATUS`, `LOCK`, `UNLOCK`, `SYNC`, `LIST_RULES`, `ADD_RULE`)
- Desktop orchestration with a policy manager UI and live core command integration
- CLI rule listing and rule creation commands
- Cloud backend with SQLite persistence for devices, policy rules, and telemetry
- Web dashboard with live device, rule, and telemetry views

### Packaging

Create a release package for distribution:

```bash
./publish.sh
```

### API security

The server uses an API key for protected endpoints. The default key is configured in `server/appsettings.json`:

```json
{
  "ApiKey": "alfa-demo-key"
}
```

Use the `X-Alfa-Api-Key` header for protected requests to:

- `POST /api/devices/pair`
- `POST /api/rules`
- `POST /api/telemetry`

> Note: The desktop app is a WPF project and is supported on Windows hosts. Building `app/desktop` on Linux is skipped by the root build script and packaging script.

## Design goals

Alfa is designed to be:

- Secure: with strong authentication, policy validation, and anti-tamper scaffolding
- Modular: clear separation of core enforcement, UI, CLI, backend, and dashboard
- Extensible: contract-driven architecture for future driver-level protection and remote management

## Documentation

See `docs/` for architecture diagrams, security model, and deployment guidance.





