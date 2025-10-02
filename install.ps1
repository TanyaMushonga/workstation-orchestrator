# Ease of use wrapper that forwards to the modular Windows installer located
# under scripts/windows/install.ps1. This keeps backwards compatibility for
# folks invoking install.ps1 from the repository root.

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Comma separated list of tool groups to install.")]
    [string]$Groups
)

if (-not $IsWindows) {
    Write-Error 'This Windows installer wrapper must be executed on Windows.'
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$windowsInstaller = Join-Path $scriptDir 'scripts/windows/install.ps1'

if (-not (Test-Path -LiteralPath $windowsInstaller)) {
    Write-Error "Unable to locate Windows installer at $windowsInstaller"
    exit 1
}

# Forward all provided parameters while preserving defaults.
& $windowsInstaller @PSBoundParameters
