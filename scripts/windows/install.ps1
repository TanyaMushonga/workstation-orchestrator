<#
.SYNOPSIS
	Cross-platform workstation bootstrapper (Windows edition).

.DESCRIPTION
	Installs curated development, DevOps, security, and productivity tooling
	on Windows using winget. Users can choose which groups to install.

.NOTES
	Run this script from an elevated PowerShell session (Run as Administrator).
#>

[CmdletBinding()]
param(
	[Parameter(HelpMessage = "Comma separated list of tool groups to install.")]
	[string]$Groups
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
	$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
	return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
	Write-Warning 'This script must be run from an elevated PowerShell session. Right-click PowerShell and choose "Run as administrator".'
	exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
	Write-Error 'winget is required but was not found. Install winget or update to Windows 10 21H2+/Windows 11, then re-run the script.'
	exit 1
}

function Ensure-DevDirectories {
	$paths = @(
		"$HOME\Development",
		"$HOME\Development\projects",
		"$HOME\Development\tools",
		"$HOME\Development\scripts"
	)
	foreach ($path in $paths) {
		if (-not (Test-Path -LiteralPath $path)) {
			New-Item -ItemType Directory -Path $path | Out-Null
			Write-Host "[INFO] Created $path"
		}
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
	Write-Host "[INFO] Installing $display"

	$arguments = @('install', '--exact', '--id', $Id, '--accept-package-agreements', '--accept-source-agreements')
	if ($Source) {
		$arguments += @('--source', $Source)
	}
	if ($AdditionalArgs) {
		$arguments += $AdditionalArgs.Split(' ')
	}

	try {
		winget @arguments
		Write-Host "[OK]   $display"
	}
	catch {
		Write-Warning "Failed to install $display: $($_.Exception.Message)"
	}
}

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

Write-Host "🚀 Windows Workstation Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Detected OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor DarkGray
Write-Host

Write-Host 'Available tool groups:'
foreach ($key in $toolGroups.Keys) {
	Write-Host ("  - {0}: {1}" -f $key, $toolGroups[$key].Description)
}

if (-not $Groups) {
	$Groups = Read-Host "Enter groups to install (comma separated, 'all' for everything, default: core,development)"
}

if ([string]::IsNullOrWhiteSpace($Groups)) {
	$Groups = 'core,development'
}

$selectedGroups = @()
if ($Groups.Trim().ToLower() -eq 'all') {
	$selectedGroups = $toolGroups.Keys
} else {
	$tokens = $Groups -split '[,\s]+'
	foreach ($token in $tokens) {
		if ([string]::IsNullOrWhiteSpace($token)) { continue }
		$key = $token.Trim().ToLower()
		if ($toolGroups.Keys -contains $key) {
			$selectedGroups += $key
		} else {
			Write-Warning "Unknown group '$token' ignored."
		}
	}
}

if ($selectedGroups.Count -eq 0) {
	Write-Warning 'No valid groups chosen. Defaulting to core.'
	$selectedGroups = @('core')
}

foreach ($group in $selectedGroups) {
	Write-Host
	Write-Host "➡️  Installing group: $group" -ForegroundColor Cyan
	$definition = $toolGroups[$group]
	foreach ($pkg in $definition.Packages) {
		Install-WingetPackage @pkg
	}
	if ($definition.ContainsKey('PostInstall') -and $definition.PostInstall) {
		& $definition.PostInstall
	}
}

Write-Host
Write-Host "✅ Completed installation for groups: $($selectedGroups -join ', ')" -ForegroundColor Green
Write-Host "• Restart your terminal to load new PATH changes." -ForegroundColor DarkGray
Write-Host "• Sign in to Docker Desktop, GitHub CLI (gh auth login), and configured cloud CLIs." -ForegroundColor DarkGray
