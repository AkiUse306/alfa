# Alfa Core Engine

The core module contains the lightweight protection enforcement engine designed to run as a persistent background service.

## Features

- Persistent heartbeat loop
- Enforcement stubs for process and file protection
- Secure IPC and command validation are planned in the architecture

## Build

```bash
cd core
cmake -S . -B build
cmake --build build
```
