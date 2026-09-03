[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path,
    [string]$EngineeringOsHome = (Join-Path ([Environment]::GetFolderPath("UserProfile")) ".engineering-os"),
    [string]$Ref = "main"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Ref) -or $Ref.StartsWith("/") -or $Ref.Contains("..")) {
    throw "Invalid Engineering OS git ref: $Ref"
}

$targetItem = Get-Item -LiteralPath $Target -ErrorAction Stop
if (-not $targetItem.PSIsContainer) {
    throw "Target project is not a directory: $Target"
}
$resolvedTarget = $targetItem.FullName
$resolvedHome = [System.IO.Path]::GetFullPath($EngineeringOsHome)

$git = Get-Command git.exe -ErrorAction SilentlyContinue
$candidates = @()
if ($git) {
    $gitRoot = Split-Path -Parent (Split-Path -Parent $git.Source)
    $candidates += (Join-Path $gitRoot "bin\bash.exe")
}
$candidates += @(
    (Join-Path $env:ProgramFiles "Git\bin\bash.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe")
)
$bash = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
if (-not $bash) {
    throw "Git Bash was not found. Install Git for Windows before installing Engineering OS."
}

$localInstaller = $null
if ($PSScriptRoot) {
    $candidate = Join-Path $PSScriptRoot "install-engineering-os-project.sh"
    $repoMarker = Join-Path (Split-Path -Parent $PSScriptRoot) ".git"
    if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and (Test-Path -LiteralPath $repoMarker)) {
        $localInstaller = $candidate
    }
}

$temporaryInstaller = $null
if ($localInstaller) {
    $installer = $localInstaller
}
else {
    $temporaryInstaller = Join-Path ([System.IO.Path]::GetTempPath()) ("engineering-os-install-" + [guid]::NewGuid().ToString("N") + ".sh")
    $uri = "https://raw.githubusercontent.com/yotamfried-ux/Engineering-OS/$Ref/scripts/install-engineering-os-project.sh"
    $installer = $temporaryInstaller
}

$previousHome = [Environment]::GetEnvironmentVariable("EOS_HOME_WINDOWS", "Process")
$previousRef = [Environment]::GetEnvironmentVariable("ENGINEERING_OS_REF", "Process")
$previousTarget = [Environment]::GetEnvironmentVariable("EOS_TARGET_WINDOWS", "Process")
try {
    if ($temporaryInstaller) {
        Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $temporaryInstaller
    }
    # Keep Windows paths out of bash -c: Windows PowerShell 5.1 reconstructs native
    # command strings differently from pwsh. The tracked Bash entry point uses cygpath
    # on these exact environment values before any installation work.
    $env:EOS_HOME_WINDOWS = $resolvedHome
    $env:EOS_TARGET_WINDOWS = $resolvedTarget
    $env:ENGINEERING_OS_REF = $Ref
    & $bash $installer.Replace("\", "/")
    if ($LASTEXITCODE -ne 0) {
        throw "Engineering OS installation or verification failed with exit code $LASTEXITCODE."
    }
}
finally {
    if ($null -eq $previousHome) {
        Remove-Item Env:\EOS_HOME_WINDOWS -ErrorAction SilentlyContinue
    }
    else {
        $env:EOS_HOME_WINDOWS = $previousHome
    }
    if ($null -eq $previousRef) {
        Remove-Item Env:\ENGINEERING_OS_REF -ErrorAction SilentlyContinue
    }
    else {
        $env:ENGINEERING_OS_REF = $previousRef
    }
    if ($null -eq $previousTarget) {
        Remove-Item Env:\EOS_TARGET_WINDOWS -ErrorAction SilentlyContinue
    }
    else {
        $env:EOS_TARGET_WINDOWS = $previousTarget
    }
    if ($temporaryInstaller) {
        Remove-Item -LiteralPath $temporaryInstaller -Force -ErrorAction SilentlyContinue
    }
}
