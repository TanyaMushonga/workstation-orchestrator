#!/usr/bin/env bash

AVAILABLE_GROUPS=(core development devops security productivity)

declare -A GROUP_DESCRIPTIONS=(
    [core]="Shell tweaks, CLI tools, Git configuration"
    [development]="Languages, databases, IDEs, SDKs"
    [devops]="Containers, cloud CLIs, infrastructure-as-code"
    [security]="Network analysis and application security tooling"
    [productivity]="Browsers, media, communication apps"
)

declare -A GROUP_FORMULAE=(
    [core]="git curl wget gnupg tree jq neofetch zsh coreutils findutils fzf"
    [development]="python node go rustup-init openjdk@21 maven gradle cmake sqlite postgresql redis"
    [devops]="awscli azure-cli kubectl helm ansible terraform"
    [security]="nmap sqlmap hashcat hydra john"
    [productivity]="tmux"
)

declare -A GROUP_CASKS=(
    [core]="iterm2"
    [development]="visual-studio-code jetbrains-toolbox postman mongodb-compass"
    [devops]="docker google-cloud-sdk"
    [security]="wireshark burp-suite"
    [productivity]="google-chrome brave-browser slack discord obs"
)
