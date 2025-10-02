#!/usr/bin/env bash

# Defines tool groups per package manager for Linux installer.

AVAILABLE_GROUPS=(core development devops security productivity)

declare -A GROUP_DESCRIPTIONS=(
    ["core"]="Shell, CLI utilities, dotfiles, Git configuration"
    ["development"]="Languages, databases, IDEs, SDK managers"
    ["devops"]="Containers, cloud CLIs, infrastructure-as-code"
    ["security"]="Security tooling appropriate for your distro"
    ["productivity"]="Browsers, media, office, communications"
)

declare -A GROUP_PACKAGES_APT=(
    ["core"]="git curl wget vim htop build-essential python3 python3-pip python3-venv nodejs npm unzip zip tree jq net-tools ca-certificates gnupg software-properties-common apt-transport-https tmux neofetch zsh ripgrep fd-find bat exa"
    ["development"]="openjdk-21-jdk maven gradle cmake make gcc g++ clang sqlite3 redis-server postgresql postgresql-contrib golang rustc cargo"
    ["devops"]="docker.io docker-compose ansible"
    ["security"]="nmap wireshark sqlmap"
    ["productivity"]="vlc obs-studio gimp imagemagick ffmpeg libreoffice"
)

declare -A GROUP_PACKAGES_DNF=(
    ["core"]="git curl wget vim htop @development-tools python3 python3-pip nodejs npm unzip zip tree jq net-tools ca-certificates gnupg2 tmux neofetch zsh ripgrep fd-find bat exa"
    ["development"]="java-21-openjdk-devel maven gradle cmake make gcc gcc-c++ clang sqlite redis postgresql-server postgresql golang rust cargo"
    ["devops"]="docker docker-compose ansible"
    ["security"]="nmap wireshark hydra john hashcat"
    ["productivity"]="vlc obs-studio gimp ImageMagick ffmpeg libreoffice"
)

declare -A GROUP_PACKAGES_PACMAN=(
    ["core"]="git curl wget vim htop base-devel python python-pip nodejs npm unzip zip tree jq net-tools ca-certificates gnupg tmux neofetch zsh ripgrep fd bat exa"
    ["development"]="jdk-openjdk maven gradle cmake make gcc gcc-libs clang sqlite redis postgresql go rust"
    ["devops"]="docker docker-compose ansible"
    ["security"]="nmap wireshark-qt hydra john hashcat"
    ["productivity"]="vlc obs-studio gimp imagemagick ffmpeg libreoffice-fresh"
)

get_group_packages() {
    local group=$1
    case $PACKAGE_MANAGER in
        apt)
            echo "${GROUP_PACKAGES_APT[$group]}"
            ;;
        dnf)
            echo "${GROUP_PACKAGES_DNF[$group]}"
            ;;
        pacman)
            echo "${GROUP_PACKAGES_PACMAN[$group]}"
            ;;
    esac
}

install_security_extras() {
    if [[ $PACKAGE_MANAGER == "apt" && $OS_ID == "kali" ]]; then
        local kali_only=("metasploit-framework" "gobuster" "nikto" "netcat-traditional" "aircrack-ng" "hydra" "john" "hashcat")
        for pkg in "${kali_only[@]}"; do
            install_package "$pkg"
        done
    fi
}
