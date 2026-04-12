# Alfa Server

The server project implements the cloud control plane API for device management, policy distribution, and telemetry ingestion.

## Run

```bash
cd server
dotnet run
```

## Endpoints

- `GET /api/health`
- `GET /api/devices`
- `POST /api/devices/pair`
- `GET /api/rules`
- `POST /api/rules`
