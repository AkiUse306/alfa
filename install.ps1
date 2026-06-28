param(
    [switch]$Uninstall,
    [switch]$Update
)

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ───────────────────────────────────────────────────────────────
#   CONFIG
# ───────────────────────────────────────────────────────────────
$AppName        = "Alfa Endpoint Protection"
$AppVersion     = "1.0"
$InstallDir     = "C:\Program Files\Alfa"
$LogDir         = "C:\ProgramData\Alfa"
$LogFile        = "$LogDir\alfa-install.log"

$MsiUrl         = "https://github.com/AkiUse306/alfa/releases/download/1.0/alfa-1.0-windows.msi"
$MsiHash        = "7E8AA2E5D6FD99E068835C6F76D0F35C6E2AD1A8F5D841B56E5881F6BDA5AC49"
$TempMsi        = "$env:TEMP\alfa-installer.msi"

# ───────────────────────────────────────────────────────────────
#   LOGGING
# ───────────────────────────────────────────────────────────────
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "OK"    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }

    Add-Content -Path $LogFile -Value $line
}

# ───────────────────────────────────────────────────────────────
#   VERSION / REGISTRY
# ───────────────────────────────────────────────────────────────
$UninstallRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Alfa"

function Get-InstalledVersion {
    if (Test-Path $UninstallRegPath) {
        return (Get-ItemProperty $UninstallRegPath).DisplayVersion
    }
    return $null
}

function Check-Version {
    $installed = Get-InstalledVersion
    if ($installed) {
        Write-Log "Detected installed version: $installed"

        if ([version]$installed -ge [version]$AppVersion -and -not $Update) {
            Write-Log "Alfa is already up to date." "OK"
            Write-Host "`nAlfa is already installed and up to date." -ForegroundColor Green
            return
        }

        Write-Log "Older version detected. Proceeding with upgrade." "WARN"
    }
}

function Register-UninstallEntry {
    if (!(Test-Path $UninstallRegPath)) {
        New-Item -Path $UninstallRegPath -Force | Out-Null
    }

    Set-ItemProperty -Path $UninstallRegPath -Name "DisplayName"   -Value $AppName
    Set-ItemProperty -Path $UninstallRegPath -Name "DisplayVersion" -Value $AppVersion
    Set-ItemProperty -Path $UninstallRegPath -Name "Publisher"     -Value "AkiUse306"
    Set-ItemProperty -Path $UninstallRegPath -Name "InstallLocation" -Value $InstallDir
    Set-ItemProperty -Path $UninstallRegPath -Name "UninstallString" -Value "msiexec.exe /x {ALFA-PRODUCT-CODE}"
}

# ───────────────────────────────────────────────────────────────
#   UNINSTALL
# ───────────────────────────────────────────────────────────────
function Uninstall-Alfa {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    New-Item -ItemType File -Path $LogFile -Force | Out-Null

    Write-Log "=== Uninstall requested by $env:USERNAME on $env:COMPUTERNAME ==="

    if (!(Test-Path $UninstallRegPath)) {
        Write-Log "Alfa is not installed." "WARN"
        Write-Host "Alfa is not installed." -ForegroundColor Yellow
        return
    }

    $uninstallCmd = (Get-ItemProperty $UninstallRegPath).UninstallString
    if (-not $uninstallCmd) {
        Write-Log "UninstallString missing in registry." "ERROR"
        Write-Host "Uninstall information is missing." -ForegroundColor Red
        return
    }

    Write-Log "Running uninstall: $uninstallCmd"

    $proc = Start-Process msiexec.exe -ArgumentList $uninstallCmd -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Log "Uninstall failed with exit code $($proc.ExitCode)" "ERROR"
        Write-Host "Uninstall failed." -ForegroundColor Red
        return
    }

    Write-Log "Uninstall completed." "OK"
    Write-Host "Alfa has been uninstalled." -ForegroundColor Green
    return
}

if ($Uninstall) {
    Uninstall-Alfa
    return
}

# ───────────────────────────────────────────────────────────────
#   CONFIG SYSTEM
# ───────────────────────────────────────────────────────────────
function Initialize-Config {
    $configPath = "$LogDir\config.json"

    if (!(Test-Path $configPath)) {
        Write-Log "Creating default config.json"

        @"
{
  "updateIntervalHours": 6,
  "serviceMode": "active",
  "logLevel": "info"
}
"@ | Set-Content $configPath
    }
}

# ───────────────────────────────────────────────────────────────
#   AUTO-UPDATE TASK
# ───────────────────────────────────────────────────────────────
function Register-AutoUpdateTask {
    Write-Log "Registering scheduled auto-update task..."

    $taskName  = "AlfaAutoUpdate"
    $scriptPath = "$InstallDir\update.ps1"

    @"
powershell -ExecutionPolicy Bypass -File `"$InstallDir\install.ps1`" -Update
"@ | Set-Content $scriptPath

    $action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger  = New-ScheduledTaskTrigger -Daily -At 3am
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force

    Write-Log "Auto-update task registered." "OK"
}

# ───────────────────────────────────────────────────────────────
#   BANNER / CONSENT
# ───────────────────────────────────────────────────────────────
function Show-Banner {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "     $AppName v$AppVersion Installer" -ForegroundColor Magenta
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  - Download and install Alfa"
    Write-Host "  - Verify MSI integrity"
    Write-Host "  - Create/Update Windows service: AlfaService"
    Write-Host "  - Register auto-update task"
    Write-Host "  - Log to: $LogFile"
    Write-Host ""
}

function Get-Consent {
    $response = Read-Host "Proceed with installation? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "Installation cancelled." -ForegroundColor Red
        return
    }
}

# ───────────────────────────────────────────────────────────────
#   DOWNLOAD / CHECKSUM
# ───────────────────────────────────────────────────────────────
function Get-Installer {
    Write-Log "Downloading MSI from $MsiUrl"

    try {
        Invoke-WebRequest -Uri $MsiUrl -OutFile $TempMsi -UseBasicParsing
        Write-Log "Download complete: $TempMsi" "OK"
    }
    catch {
        Write-Log "Download failed: $_" "ERROR"
        Write-Host "Download failed." -ForegroundColor Red
        return
    }
}

function Confirm-Checksum {
    Write-Log "Verifying SHA-256 checksum..."

    $actual = (Get-FileHash $TempMsi -Algorithm SHA256).Hash

    if ($actual -ne $MsiHash) {
        Write-Log "Checksum mismatch! Expected: $MsiHash  Got: $actual" "ERROR"
        Remove-Item $TempMsi -Force
        Write-Host "Checksum verification failed." -ForegroundColor Red
        return
    }

    Write-Log "Checksum OK." "OK"
}

# ───────────────────────────────────────────────────────────────
#   MSI INSTALL / SERVICE
# ───────────────────────────────────────────────────────────────
function Install-Msi {
    Write-Log "Starting MSI installation..."

    $args = "/i `"$TempMsi`" /l*v `"$LogDir\msi-install.log`""

    $proc = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru

    if ($proc.ExitCode -ne 0) {
        Write-Log "MSI exited with code $($proc.ExitCode)" "ERROR"
        Write-Host "MSI installation failed." -ForegroundColor Red
        return
    }

    Write-Log "MSI installation completed successfully." "OK"
}

function Create-Service {
    $serviceName = "AlfaService"
    $exePath     = "$InstallDir\Alfa.exe"

    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Write-Log "Service already exists. Restarting..." "WARN"
        Restart-Service $serviceName -Force
        return
    }

    Write-Log "Creating Windows service: $serviceName"
    New-Service -Name $serviceName -BinaryPathName "`"$exePath`"" -DisplayName $AppName -StartupType Automatic
    Start-Service $serviceName
    Write-Log "Service created and started." "OK"
}

function Remove-Temp {
    if (Test-Path $TempMsi) {
        Remove-Item $TempMsi -Force
        Write-Log "Temporary installer removed." "INFO"
    }
}

# ───────────────────────────────────────────────────────────────
#   MAIN
# ───────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
if (!(Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile -Force | Out-Null }

Show-Banner
Initialize-Config
Check-Version
Get-Consent

Write-Log "=== Installation started by $env:USERNAME on $env:COMPUTERNAME ==="

Get-Installer
Confirm-Checksum
Install-Msi
Create-Service
Register-AutoUpdateTask
Register-UninstallEntry
Remove-Temp

Write-Log "=== Installation complete ===" "OK"
Write-Host "`Alfa installed successfully." -ForegroundColor Green
return
