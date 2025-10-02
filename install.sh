#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OS_NAME=$(uname -s)

case $OS_NAME in
    Linux)
        exec "$ROOT_DIR/scripts/linux/install.sh" "$@"
        ;;
    Darwin)
        exec "$ROOT_DIR/scripts/macos/install.sh" "$@"
        ;;
    *)
        cat <<'EOF'
Unsupported platform for this entrypoint.

• Linux users: invoke ./install.sh from a bash shell (already handled).
• macOS users: ensure Homebrew is installed, then run ./install.sh again.
• Windows users: execute install.ps1 from an elevated PowerShell session.
EOF
        exit 1
        ;;
 esac
