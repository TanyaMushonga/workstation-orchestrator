#!/usr/bin/env bash

# Package installation helpers for different Linux package managers.

install_package() {
    local package=$1
    if [[ -z $package ]]; then
        return
    fi

    case $PACKAGE_MANAGER in
        apt)
            if sudo apt-get install -y "$package" >/dev/null 2>&1; then
                log_success "Installed $package"
            else
                log_warning "Failed to install $package"
            fi
            ;;
        dnf)
            if sudo dnf install -y "$package" >/dev/null 2>&1; then
                log_success "Installed $package"
            else
                log_warning "Failed to install $package"
            fi
            ;;
        pacman)
            if sudo pacman -S --noconfirm --needed "$package" >/dev/null 2>&1; then
                log_success "Installed $package"
            else
                log_warning "Failed to install $package"
            fi
            ;;
    esac
}

install_packages() {
    local list=$1
    if [[ -z $list ]]; then
        return
    fi

    # shellcheck disable=SC2086
    for package in $list; do
        install_package "$package"
    done
}
