# Alfa Desktop App

The desktop application is the user-facing orchestration layer. It manages rules, displays logs, and communicates with the core engine and cloud control plane.

## Project structure

- `App.xaml` / `App.xaml.cs` — application bootstrap
- `MainWindow.xaml` — starter UI shell
- `MainWindow.xaml.cs` — UI event hooks

## Build

```bash
cd app/desktop
dotnet build -c Release
```
