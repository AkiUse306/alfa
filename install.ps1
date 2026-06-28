#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Alfa Endpoint Protection - Installer
.DESCRIPTION
    Installs Alfa on this machine. Requires administrator rights.
    All actions are logged to C:\ProgramData\Alfa\install.log
.NOTES
    Run with: powershell -ExecutionPolicy Bypass -File install.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Config ──────────────────────────────────────────────────────────────────
$AppName        = "Alfa Endpoint Protection"
$AppVersion     = "1.0"
$InstallDir     = "C:\Program Files\Alfa"
$LogDir         = "C:\ProgramData\Alfa"
$LogFile        = "$LogDir\alfa-install.log"
$MsiUrl         = "https://github.com/AkiUse306/alfa/releases/tag/1.0/alfa-1.0.msi"   
$MsiHash        = "7E8AA2E5D6FD99E068835C6F76D0F35C6E2AD1A8F5D841B56E5881F6BDA5AC49"                               
$TempMsi        = "$env:TEMP\alfa-installer.msi"

# ── Logging ─────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# ── Banner ───────────────────────────────────────────────────────────────────
function Show-Banner {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $AppName v$AppVersion Installer" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  1. Download the Alfa MSI from: $MsiUrl"
    Write-Host "  2. Verify its SHA-256 checksum"
    Write-Host "  3. Install Alfa to: $InstallDir"
    Write-Host "  4. Create a Windows service: AlfaService"
    Write-Host "  5. Log all actions to: $LogFile"
    Write-Host ""
    Write-Host "Alfa requires the following permissions:" -ForegroundColor Yellow
    Write-Host "  - Run as a Windows service (SYSTEM)"
    Write-Host "  - Read/write to $InstallDir"
    Write-Host "  - Read/write to $LogDir"
    Write-Host "  [Add any other permissions your app needs here]"
    Write-Host ""
}

# ── Consent ──────────────────────────────────────────────────────────────────
function Get-Consent {
    $response = Read-Host "Do you want to proceed? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "Installation cancelled by user." -ForegroundColor Red
        exit 0
    }
}

# ── Download ─────────────────────────────────────────────────────────────────
function Get-Installer {
    Write-Log "Downloading installer from $MsiUrl"
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($MsiUrl, $TempMsi)
        Write-Log "Download complete: $TempMsi"
    } catch {
        Write-Log "Download failed: $_" -Level "ERROR"
        throw
    }
}

# ── Checksum ─────────────────────────────────────────────────────────────────
function Confirm-Checksum {
    Write-Log "Verifying SHA-256 checksum..."
    $actual = (Get-FileHash -Path $TempMsi -Algorithm SHA256).Hash
    if ($actual -ne $MsiHash) {
        Write-Log "Checksum MISMATCH. Expected: $MsiHash  Got: $actual" -Level "ERROR"
        Remove-Item $TempMsi -Force
        throw "Checksum verification failed. Installation aborted."
    }
    Write-Log "Checksum verified OK: $actual"
}

# ── Install ──────────────────────────────────────────────────────────────────
function Install-Msi {
    Write-Log "Starting MSI installation (visible UI)..."
    $args = @(
        "/i", $TempMsi,
        "/l*v", "$LogDir\msi-install.log"   # verbose MSI log, NO /qn
    )
    $proc = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Log "MSI exited with code $($proc.ExitCode)" -Level "ERROR"
        throw "Installation failed. See $LogDir\msi-install.log for details."
    }
    Write-Log "MSI installation completed successfully."
}

# ── Cleanup ──────────────────────────────────────────────────────────────────
function Remove-Temp {
    if (Test-Path $TempMsi) {
        Remove-Item $TempMsi -Force
        Write-Log "Temporary installer removed."
    }
}

# ── Main ─────────────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

Show-Banner
Get-Consent

Write-Log "=== Alfa installation started by $env:USERNAME on $env:COMPUTERNAME ==="

Get-Installer
Confirm-Checksum
Install-Msi
Remove-Temp

Write-Log "=== Installation complete ==="
Write-Host ""
Write-Host "Alfa has been installed successfully." -ForegroundColor Green
Write-Host "Log file: $LogFile"
