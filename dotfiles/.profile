# ~/.profile: executed by the command interpreter for login shells.

# Android Development
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Java Development
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Node.js Development
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python Development
export PATH=$PATH:$HOME/.local/bin

# Local development
export PATH=$PATH:$HOME/.local/bin

# Editor
export EDITOR=vim
export VISUAL=code

# Development directories
export DEV_HOME=$HOME/Development
export PROJECTS_DIR=$DEV_HOME/projects
export TOOLS_DIR=$DEV_HOME/tools
export SCRIPTS_DIR=$DEV_HOME/scripts

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Kubernetes
export KUBECONFIG=$HOME/.kube/config

# Load bashrc if it exists
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
