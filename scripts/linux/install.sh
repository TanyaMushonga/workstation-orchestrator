#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/package_manager.sh"
source "$SCRIPT_DIR/groups.sh"
source "$SCRIPT_DIR/actions.sh"

SELECTED_GROUPS=()

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

    if [[ $selection == "all" ]]; then
        SELECTED_GROUPS=("${AVAILABLE_GROUPS[@]}")
        return
    fi

    SELECTED_GROUPS=()
    for token in $selection; do
        if [[ " ${AVAILABLE_GROUPS[*]} " =~ " $token " ]]; then
            SELECTED_GROUPS+=("$token")
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
    echo "  • Reboot recommended to finalise system updates."
    echo "  • Run 'gh auth login', 'aws configure', etc. as required."
    echo "  • Log out/in to activate Docker group membership."
}

main() {
    echo "🚀 Linux Workstation Setup"
    echo "=========================="
    detect_platform
    prompt_for_groups
    update_system

    for group in "${SELECTED_GROUPS[@]}"; do
        local fn="run_group_${group}"
        if declare -f "$fn" >/dev/null 2>&1; then
            echo
            log_info "Installing group: $group"
            "$fn"
        else
            log_warning "No handler defined for group '$group'."
        fi
    done

    print_summary
}

main "$@"
