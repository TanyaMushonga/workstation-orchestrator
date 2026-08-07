<#
.SYNOPSIS
    Windows workstation bootstrapper - Installs development tools using winget.

.DESCRIPTION
    Installs curated development, DevOps, security, and productivity tooling
    on Windows using winget. Users can choose which groups to install.

.NOTES
    Run this script from an elevated PowerShell session (Run as Administrator).
    Author: Workstation Orchestrator
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Comma separated list of tool groups to install.")]
    [string]$Groups,
    
    [Parameter(HelpMessage = "Skip execution policy warning.")]
    [switch]$SkipPolicyCheck,
    
    [Parameter(HelpMessage = "Skip administrator check (not recommended).")]
    [switch]$SkipAdminCheck
)

# Set strict error handling
$ErrorActionPreference = 'Stop'

# Check execution policy
if (-not $SkipPolicyCheck) {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted") {
        Write-Warning "Execution Policy is set to 'Restricted'"
        Write-Host "Attempting to set Execution Policy to RemoteSigned for this session..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
            Write-Host "Execution Policy temporarily set to RemoteSigned for this session." -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not set Execution Policy. Try running:"
            Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" -ForegroundColor Cyan
            exit 1
        }
    }
}

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for administrator privileges
if (-not $SkipAdminCheck -and -not (Test-IsAdministrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "Alternatively, re-run with: " -NoNewline
    Write-Host "powershell -Command ""Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath""'""" -ForegroundColor Cyan
    exit 1
}

# Function to install winget if not present
function Install-WingetIfMissing {
    Write-Host "Checking for winget..." -ForegroundColor Cyan
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[OK] winget is already installed" -ForegroundColor Green
        return
    }
    
    Write-Host "winget not found. Attempting to install..." -ForegroundColor Yellow
    
    # Try different methods to install winget
    $wingetInstalled = $false
    
    # Method 1: Install from Microsoft Store via App Installer
    try {
        Write-Host "Installing winget from Microsoft Store..." -ForegroundColor Cyan
        $storeApp = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
        if (-not $storeApp) {
            # Try to install via Add-AppxPackage
            $url = "https://aka.ms/getwinget"
            $downloader = New-Object System.Net.WebClient
            $tempFile = [System.IO.Path]::GetTempFileName() + ".msixbundle"
            $downloader.DownloadFile($url, $tempFile)
            
            Add-AppxPackage -Path $tempFile -ErrorAction SilentlyContinue
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "[OK] winget installed successfully" -ForegroundColor Green
            $wingetInstalled = $true
        }
    }
    catch {
        Write-Warning "Failed to install winget via Microsoft Store method: $($_.Exception.Message)"
    }
    
    # Method 2: Install via PowerShell module
    if (-not $wingetInstalled) {
        try {
            Write-Host "Trying alternative winget installation..." -ForegroundColor Yellow
            # Install via PowerShell module
            Install-Module -Name Microsoft.WinGet.Client -Force -AllowClobber -Scope CurrentUser
            Import-Module Microsoft.WinGet.Client
            
            # Try to find winget after module installation
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-Host "[OK] winget installed via PowerShell module" -ForegroundColor Green
                $wingetInstalled = $true
            }
        }
        catch {
            Write-Warning "Failed to install winget via PowerShell module: $($_.Exception.Message)"
        }
    }
    
    if (-not $wingetInstalled) {
        Write-Error "Could not install winget. Please install it manually from:"
        Write-Host "https://github.com/microsoft/winget-cli/releases" -ForegroundColor Cyan
        Write-Host "Or install via Microsoft Store: ms-windows-store://pdp/?productid=9NBLGGH4NNS1" -ForegroundColor Cyan
        exit 1
    }
}

function Ensure-DevDirectories {
    Write-Host "Creating development directories..." -ForegroundColor Cyan
    $paths = @(
        "$HOME\Development",
        "$HOME\Development\projects",
        "$HOME\Development\tools",
        "$HOME\Development\scripts"
    )
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "  [OK] Created $path" -ForegroundColor Green
        }
    }
}

function Get-WingetExecutable {
    $command = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $command = Get-Command winget -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $windowsAppsPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path -LiteralPath $windowsAppsPath) {
        return $windowsAppsPath
    }

    return $null
}

function Invoke-WingetCommand {
    param(
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $wingetPath = Get-WingetExecutable
    if (-not $wingetPath) {
        throw 'winget could not be located. Install the Microsoft App Installer from the Microsoft Store and try again.'
    }

    $output = & $wingetPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Source,
        [string]$Name,
        [string]$AdditionalArgs
    )

    $display = if ($Name) { $Name } else { $Id }
    Write-Host "Installing $display..." -ForegroundColor Cyan

    $arguments = @('install', '--id', $Id, '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity', '--silent')
    if ($Source) {
        $arguments += @('--source', $Source)
    }
    if ($AdditionalArgs) {
        $arguments += $AdditionalArgs.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    }

    try {
        $result = Invoke-WingetCommand -Arguments $arguments
        if ($result.ExitCode -eq 0) {
            Write-Host "  [OK] $display" -ForegroundColor Green
        } elseif ($result.ExitCode -eq -1978335189 -or (($result.Output | Out-String) -match 'already installed')) {
            Write-Host "  [INFO] $display is already installed" -ForegroundColor Blue
        } else {
            Write-Warning "  [WARN] winget returned exit code $($result.ExitCode) for $display"
            $outputText = ($result.Output | Out-String).Trim()
            if ($outputText) {
                Write-Host "    $outputText" -ForegroundColor DarkYellow
            }
        }
    }
    catch {
        Write-Warning "  [ERROR] Failed to install ${display}: $($_.Exception.Message)"
    }
}

# Main tool groups definition
$toolGroups = [ordered]@{
    core = @{
        Description = 'Essential developer tooling, shells, and convenience utilities.'
        Packages = @(
            @{ Id = 'Git.Git'; Name = 'Git' }
            @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' }
            @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'Oh My Posh' }
            @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' }
            @{ Id = 'sharkdp.bat'; Name = 'bat' }
            @{ Id = 'BurntSushi.ripgrep'; Name = 'ripgrep' }
            @{ Id = 'sharkdp.fd'; Name = 'fd' }
        )
        PostInstall = { Ensure-DevDirectories }
    }
    development = @{
        Description = 'Programming languages, databases, IDEs, and API tools.'
        Packages = @(
            @{ Id = 'Python.Python.3.12'; Name = 'Python 3' }
            @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' }
            @{ Id = 'GoLang.Go'; Name = 'Go' }
            @{ Id = 'Rustlang.Rustup'; Name = 'Rust toolchain' }
            @{ Id = 'EclipseAdoptium.Temurin.21.JDK'; Name = 'Java 21 (Temurin)' }
            @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' }
            @{ Id = 'JetBrains.Toolbox'; Name = 'JetBrains Toolbox' }
            @{ Id = 'Postman.Postman'; Name = 'Postman' }
            @{ Id = 'MongoDB.Compass.Full'; Name = 'MongoDB Compass' }
            @{ Id = 'Microsoft.SQLServerManagementStudio'; Name = 'SQL Server Management Studio' }
        )
    }
    devops = @{
        Description = 'Containers, cloud CLIs, Kubernetes, and infrastructure as code.'
        Packages = @(
            @{ Id = 'Docker.DockerDesktop'; Name = 'Docker Desktop' }
            @{ Id = 'Canonical.Multipass'; Name = 'Multipass' }
            @{ Id = 'Amazon.AWSCLI'; Name = 'AWS CLI' }
            @{ Id = 'Microsoft.AzureCLI'; Name = 'Azure CLI' }
            @{ Id = 'Google.CloudSDK'; Name = 'Google Cloud SDK' }
            @{ Id = 'Kubernetes.kubectl'; Name = 'kubectl' }
            @{ Id = 'Hashicorp.Terraform'; Name = 'Terraform' }
            @{ Id = 'Kubernetes.minikube'; Name = 'Minikube' }
        )
    }
    security = @{
        Description = 'Network analysis, web testing, and offensive security utilities.'
        Packages = @(
            @{ Id = 'Nmap.Nmap'; Name = 'Nmap' }
            @{ Id = 'WiresharkFoundation.Wireshark'; Name = 'Wireshark' }
            @{ Id = 'PortSwigger.BurpSuiteCommunityEdition'; Name = 'Burp Suite Community' }
            @{ Id = 'OWASP.ZedAttackProxy'; Name = 'OWASP ZAP' }
            @{ Id = 'Netresec.NetworkMiner'; Name = 'NetworkMiner' }
            @{ Id = 'GitHub.cli'; Name = 'GitHub CLI' }
        )
    }
    productivity = @{
        Description = 'Browsers, office suite, media, and communication apps.'
        Packages = @(
            @{ Id = 'Google.Chrome'; Name = 'Google Chrome' }
            @{ Id = 'BraveSoftware.BraveBrowser'; Name = 'Brave Browser' }
            @{ Id = 'LibreOffice.LibreOffice'; Name = 'LibreOffice' }
            @{ Id = 'VideoLAN.VLC'; Name = 'VLC' }
            @{ Id = 'OBSProject.OBSStudio'; Name = 'OBS Studio' }
            @{ Id = 'GIMP.GIMP'; Name = 'GIMP' }
            @{ Id = 'Discord.Discord'; Name = 'Discord' }
            @{ Id = 'SlackTechnologies.Slack'; Name = 'Slack' }
            @{ Id = 'Spotify.Spotify'; Name = 'Spotify' }
        )
    }
}

# Display banner
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   Windows Workstation Setup Wizard" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "OS Version: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor DarkGray
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor DarkGray
Write-Host "User: $env:USERNAME" -ForegroundColor DarkGray
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

# Install winget if needed
Install-WingetIfMissing

Write-Host ""
Write-Host "Available tool groups:" -ForegroundColor Cyan
Write-Host ""

$index = 1
foreach ($key in $toolGroups.Keys) {
    Write-Host ("  [{0}] {1}: {2}" -f $index, $key, $toolGroups[$key].Description)
    $index++
}

Write-Host ""
if (-not $Groups) {
    Write-Host "You can install:"
    Write-Host "  - All groups: 'all'"
    Write-Host "  - Specific groups: 'core,development'"
    Write-Host "  - Single group: 'devops'"
    $Groups = Read-Host "Enter groups to install (comma separated, default: core,development)"
}

if ([string]::IsNullOrWhiteSpace($Groups)) {
    $Groups = 'core,development'
}

$selectedGroups = @()
if ($Groups.Trim().ToLower() -eq 'all') {
    $selectedGroups = $toolGroups.Keys
    Write-Host "Selected: All groups" -ForegroundColor Green
} else {
    $tokens = $Groups -split '[,\s]+'
    foreach ($token in $tokens) {
        if ([string]::IsNullOrWhiteSpace($token)) { continue }
        $key = $token.Trim().ToLower()
        if ($toolGroups.Keys -contains $key) {
            $selectedGroups += $key
            Write-Host "Selected: $key" -ForegroundColor Green
        } else {
            Write-Warning "Unknown group '$token' ignored."
        }
    }
}

if ($selectedGroups.Count -eq 0) {
    Write-Warning 'No valid groups chosen. Defaulting to core.'
    $selectedGroups = @('core')
}

Write-Host ""
Write-Host "Starting installation..." -ForegroundColor Cyan
Write-Host "This may take a while depending on your internet connection." -ForegroundColor Yellow
Write-Host ""

foreach ($group in $selectedGroups) {
    Write-Host ""
    Write-Host "Installing group: $group" -ForegroundColor Cyan
    Write-Host "-------------------------------------"
    
    $definition = $toolGroups[$group]
    foreach ($pkg in $definition.Packages) {
        Install-WingetPackage @pkg
    }
    if ($definition.ContainsKey('PostInstall') -and $definition.PostInstall) {
        & $definition.PostInstall
    }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  - Restart your terminal to load new PATH changes" -ForegroundColor Gray
Write-Host "  - Configure Git:" -ForegroundColor Gray
Write-Host "    git config --global user.name 'Your Name'" -ForegroundColor DarkGray
Write-Host "    git config --global user.email 'your.email@example.com'" -ForegroundColor DarkGray
Write-Host "  - Sign in to Docker Desktop" -ForegroundColor Gray
Write-Host "  - Authenticate GitHub CLI: gh auth login" -ForegroundColor Gray
Write-Host "  - Configure cloud CLIs (AWS, Azure, GCP)" -ForegroundColor Gray
Write-Host ""
Write-Host "Installed groups: $($selectedGroups -join ', ')" -ForegroundColor Green
Write-Host "Total packages installed: See above for details" -ForegroundColor Green
Write-Host ""
