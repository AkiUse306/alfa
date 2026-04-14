# Alfa Deployment Guide

## Local development

1. Install .NET 10 SDK.
2. Install CMake.
3. Run `./build.sh` from the repository root.

## Running modules

- `core` — builds to `core/build` and can be run as a local service
- `server` — ASP.NET Core backend for device and policy management
- `web` — C# Blazor Server dashboard
- `cli` — run via `dotnet run -- --status`
- `app/desktop` — WPF desktop app (Windows only)

## CI/CD

The repository includes GitHub Actions workflow `.github/workflows/ci.yml` to validate the build for core, shared, server, CLI, and the Windows desktop app.
