<#
.SYNOPSIS
  Install-Alfa.ps1 - Readable, expanded MSI installer for AkiUse306/alfa

.DESCRIPTION
  Downloads the latest GitHub release for AkiUse306/alfa that contains an .msi asset
  and runs the installer. The script is written to be easy to read and maintain:
    - clear functions
    - explicit error handling
    - optional interactive or silent install
    - elevation when required

USAGE
  Save as Install-Alfa.ps1 and run from PowerShell:
    powershell -ExecutionPolicy Bypass -File .\Install-Alfa.ps1

  To run from an elevated PowerShell prompt:
    Start PowerShell as Administrator, then run the script.

NOTES
  - Requires network access to api.github.com
  - Uses TLS 1.2 for GitHub API calls
#>

#region Preparations and Helpers

# Ensure TLS 1.2 for GitHub API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Basic settings
$Repo    = "AkiUse306/alfa"
$ApiUrl  = "https://api.github.com/repos/$Repo/releases/latest"
$UserAgent = "alfa-windows-installer/1.0"

# Create a temporary directory for downloads
$TempDir = Join-Path -Path $env:TEMP -ChildPath ("alfa-installer-{0}" -f ([guid]::NewGuid().ToString()))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Ensure cleanup on exit
$cleanupAction = {
    try {
        if (Test-Path -Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # ignore cleanup errors
    }
}
Register-EngineEvent PowerShell.Exiting -Action $cleanupAction | Out-Null

# Logging helpers
function Write-Info { param([string]$m) Write-Host " [INFO]  $m" -ForegroundColor Cyan }
function Write-Warn { param([string]$m) Write-Host " [WARN]  $m" -ForegroundColor Yellow }
function Write-ErrorAndExit { param([string]$m, [int]$code = 1) Write-Host " [ERROR] $m" -ForegroundColor Red; exit $code }

#endregion

#region Fetch latest release metadata

Write-Host ""
Write-Host "====================================="
Write-Host "🚀 Alfa Installer for Windows (MSI)"
Write-Host "====================================="
Write-Host ""

Write-Info "Querying latest release for repository: $Repo"

$Headers = @{
    "User-Agent" = $UserAgent
    "Accept"     = "application/vnd.github.v3+json"
}

try {
    $release = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -ErrorAction Stop
} catch {
    Write-ErrorAndExit "Failed to fetch release metadata from GitHub: $($_.Exception.Message)"
}

if (-not $release) {
    Write-ErrorAndExit "No release information returned from GitHub."
}

#endregion

#region Select MSI asset

Write-Info "Searching for .msi asset in the latest release..."

$msiAsset = $null

if ($release.assets -and $release.assets.Count -gt 0) {
    # Prefer assets that end with .msi (case-insensitive)
    $msiAsset = $release.assets | Where-Object {
        $_.browser_download_url -match '\.msi$'
    } | Select-Object -First 1
}

if (-not $msiAsset) {
    Write-Warn "No .msi asset found in the latest release."
    Write-Host ""
    Write-Host "Available assets (name : url):"
    foreach ($a in $release.assets) {
        Write-Host " - $($a.name) : $($a.browser_download_url)"
    }
    Write-ErrorAndExit "Please provide an .msi release asset or install manually."
}

$AssetName = $msiAsset.name
$AssetUrl  = $msiAsset.browser_download_url

Write-Info "Selected asset: $AssetName"
Write-Info "Download URL: $AssetUrl"

#endregion

#region Download MSI

$OutPath = Join-Path -Path $TempDir -ChildPath $AssetName

Write-Host ""
Write-Info "Downloading MSI to: $OutPath"

try {
    Invoke-WebRequest -Uri $AssetUrl -Headers $Headers -OutFile $OutPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-ErrorAndExit "Failed to download MSI: $($_.Exception.Message)"
}

if (-not (Test-Path -Path $OutPath)) {
    Write-ErrorAndExit "Download failed; file not found at $OutPath"
}

Write-Info "Download completed."

#endregion

#region Installer execution helpers

function Is-Administrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-MsiInstall {
    param(
        [Parameter(Mandatory=$true)][string]$MsiPath,
        [Parameter(Mandatory=$true)][bool]$Silent
    )

    $msiFull = (Resolve-Path -Path $MsiPath).Path

    if ($Silent) {
        $msiArgs = "/i `"$msiFull`" /qn /norestart"
    } else {
        $msiArgs = "/i `"$msiFull`" /norestart"
    }

    if (Is-Administrator) {
        Write-Info "Running msiexec as Administrator..."
        $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
        return $proc.ExitCode
    } else {
        Write-Info "Requesting elevation to run msiexec..."
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "msiexec.exe"
            $psi.Arguments = $msiArgs
            $psi.Verb = "runas"
            $psi.UseShellExecute = $true
            $p = [System.Diagnostics.Process]::Start($psi)
            $p.WaitForExit()
            return $p.ExitCode
        } catch {
            Write-Warn "Elevation was cancelled or failed."
            return 1602  # MSI user cancelled
        }
    }
}

#endregion

#region Ask user for install mode

Write-Host ""
Write-Host "Choose installation mode:"
Write-Host "  [S] Silent (recommended for scripts)"
Write-Host "  [I] Interactive (shows installer UI)"
Write-Host ""

$choice = Read-Host "Enter S or I (default: S)"
if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = "S"
}
$choice = $choice.Trim().ToUpperInvariant()

switch ($choice) {
    "I" { $silent = $false }
    default { $silent = $true }
}

if ($silent) {
    Write-Info "Selected: Silent install"
} else {
    Write-Info "Selected: Interactive install"
}

#endregion

#region Run installer

Write-Host ""
Write-Info "Starting installer..."

$exitCode = Start-MsiInstall -MsiPath $OutPath -Silent:$silent

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "✅ Alfa installed successfully!"
    Write-Host ""
    Write-Host "You can run:"
    Write-Host "  alfa"
    Write-Host ""
    exit 0
} elseif ($exitCode -eq 1602) {
    Write-Warn "Installation cancelled by user."
    Write-Host "If you want to run the installer manually, the MSI is at:"
    Write-Host "  $OutPath"
    exit 2
} else {
    Write-Warn "Installer exited with code $exitCode."
    Write-Host "If the install failed, try running the MSI manually:"
    Write-Host "  msiexec /i `"$OutPath`""
    exit $exitCode
}

#endregion
