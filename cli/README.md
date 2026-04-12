# Alfa CLI

The CLI provides a developer-friendly interface to the Alfa platform.

## Supported commands

- `alfa --code` — generate a secure device pairing code
- `alfa --status` — display local Alfa status
- `alfa --lock <app>` — request a lock on a target application
- `alfa --unlock <app>` — request unlocking of a target application
- `alfa --sync` — synchronize policies with the control plane

## Run

```bash
cd cli
dotnet run -- --status
```
