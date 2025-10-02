#!/usr/bin/env bash

# Platform detection and system update helpers.

OS_NAME=""
OS_ID=""
PACKAGE_MANAGER=""

ensure_command() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command '$cmd' was not found."
        exit 1
    fi
}

detect_platform() {
    if [[ $(uname -s) != "Linux" ]]; then
        log_error "This installer supports Linux systems only."
        exit 1
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_NAME=${PRETTY_NAME:-$NAME}
        OS_ID=${ID:-}
    fi

    if [[ -z ${OS_ID} ]]; then
        log_warning "Unable to detect distribution ID from /etc/os-release. Falling back to package manager detection."
    fi

    case ${OS_ID} in
        ubuntu|debian|kali|linuxmint|pop|elementary|zorin)
            PACKAGE_MANAGER="apt"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            PACKAGE_MANAGER="dnf"
            ;;
        arch|manjaro|endeavouros)
            PACKAGE_MANAGER="pacman"
            ;;
        *)
            if command -v apt-get >/dev/null 2>&1; then
                PACKAGE_MANAGER="apt"
            elif command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            elif command -v pacman >/dev/null 2>&1; then
                PACKAGE_MANAGER="pacman"
            else
                log_error "Unsupported distribution. Please use an apt, dnf, or pacman based system."
                exit 1
            fi
            ;;
    esac

    OS_NAME=${OS_NAME:-Unknown Linux}
    log_info "Detected platform: $OS_NAME (package manager: $PACKAGE_MANAGER)"
}

update_system() {
    case $PACKAGE_MANAGER in
        apt)
            log_info "Updating apt repositories..."
            sudo apt-get update -y && sudo apt-get upgrade -y
            ;;
        dnf)
            log_info "Updating dnf repositories..."
            sudo dnf upgrade --refresh -y
            ;;
        pacman)
            log_info "Synchronising pacman packages..."
            sudo pacman -Syu --noconfirm
            ;;
        *)
            log_warning "Skipping system update for unsupported manager: $PACKAGE_MANAGER"
            ;;
    esac
}
