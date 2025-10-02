#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/groups.sh"

SELECTED_GROUPS=()

require_modern_bash() {
    if [[ ${BASH_VERSINFO[0]:-0} -lt 4 ]]; then
        log_error "This installer requires bash 4 or newer. Install Homebrew bash (brew install bash) and invoke it with /usr/local/bin/bash scripts/macos/install.sh"
        exit 1
    fi
}

ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew is required. Install from https://brew.sh and re-run the script."
        exit 1
    fi
}

update_homebrew() {
    log_info "Updating Homebrew..."
    brew update
}

install_formula() {
    local formula=$1
    if brew list "$formula" >/dev/null 2>&1; then
        log_info "$formula already installed"
        return
    fi
    if brew install "$formula" >/dev/null 2>&1; then
        log_success "Installed $formula"
    else
        log_warning "Failed to install $formula"
    fi
}

install_cask() {
    local cask=$1
    if brew list --cask "$cask" >/dev/null 2>&1; then
        log_info "$cask already installed"
        return
    fi
    if brew install --cask "$cask" >/dev/null 2>&1; then
        log_success "Installed $cask"
    else
        log_warning "Failed to install $cask"
    fi
}

install_group() {
    local group=$1
    local formulas="${GROUP_FORMULAE[$group]:-}"
    local casks="${GROUP_CASKS[$group]:-}"

    if [[ -n $formulas ]]; then
        for formula in $formulas; do
            install_formula "$formula"
        done
    fi

    if [[ -n $casks ]]; then
        for cask in $casks; do
            install_cask "$cask"
        done
    fi
}

run_post_install_core() {
    log_info "Configuring developer directories..."
    mkdir -p "$HOME/Development"/{projects,tools,scripts}

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1; then
            log_success "Oh My Zsh installed"
        else
            log_warning "Failed to install Oh My Zsh"
        fi
    fi

    if [[ -d "$SCRIPT_DIR/../../dotfiles" ]]; then
        for file in .zshrc .bash_aliases .vimrc .profile .bashrc; do
            if [[ -f "$SCRIPT_DIR/../../dotfiles/$file" ]]; then
                cp -f "$SCRIPT_DIR/../../dotfiles/$file" "$HOME/$file"
                log_info "Applied dotfile $file"
            fi
        done
    fi
}

run_post_install_devops() {
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker Desktop installed. Launch it once to finish setup."
    fi
}

prompt_for_groups() {
    log_info "Available tool groups:"
    for group in "${AVAILABLE_GROUPS[@]}"; do
        printf '  - %-12s %s\n' "$group" "${GROUP_DESCRIPTIONS[$group]}"
    done
    echo
    read -r -p "Enter groups to install (space separated, 'all' for everything, default: core development): " selection || selection=""

    if [[ -z $selection ]]; then
        selection="core development"
    fi

    if [[ ${selection,,} == "all" ]]; then
        SELECTED_GROUPS=("${AVAILABLE_GROUPS[@]}")
        return
    fi

    SELECTED_GROUPS=()
    for token in $selection; do
        local normalized=${token,,}
        if [[ " ${AVAILABLE_GROUPS[*]} " =~ " $normalized " ]]; then
            SELECTED_GROUPS+=("$normalized")
        else
            log_warning "Unknown group '$token' ignored."
        fi
    done

    if [[ ${#SELECTED_GROUPS[@]} -eq 0 ]]; then
        log_warning "No valid groups selected. Defaulting to 'core'."
        SELECTED_GROUPS=("core")
    fi
}

print_summary() {
    echo
    log_success "Completed installation for groups: ${SELECTED_GROUPS[*]}"
    echo
    log_info "Next steps:"
    echo "  • Restart terminal to refresh PATH."
    echo "  • Run 'brew doctor' to verify Homebrew health."
    echo "  • Sign into Docker Desktop, cloud CLIs, and IDEs as needed."
}

main() {
    echo "🍎 macOS Workstation Setup"
    echo "=========================="
    require_modern_bash
    ensure_homebrew
    prompt_for_groups
    update_homebrew

    for group in "${SELECTED_GROUPS[@]}"; do
        echo
        log_info "Installing group: $group"
        install_group "$group"
        case $group in
            core)
                run_post_install_core
                ;;
            devops)
                run_post_install_devops
                ;;
        esac
    done

    print_summary
}

main "$@"
