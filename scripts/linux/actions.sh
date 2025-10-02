#!/usr/bin/env bash

# Per-group actions beyond package installation.

source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/platform.sh"
source "$(dirname "$0")/lib/package_manager.sh"
source "$(dirname "$0")/groups.sh"

setup_directories() {
    log_info "Creating development directories..."
    mkdir -p "$HOME/Development"/{projects,tools,scripts}
    mkdir -p "$HOME/Android/Sdk"
    mkdir -p "$HOME/.local/bin"
}

setup_zsh() {
    if command -v zsh >/dev/null 2>&1; then
        log_info "Zsh already installed."
    else
        install_package "zsh"
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1; then
            log_success "Oh My Zsh installed."
        else
            log_warning "Failed to install Oh My Zsh."
        fi
    fi

    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(command -v zsh)" "$USER" >/dev/null 2>&1 || log_warning "Unable to set Zsh as default shell automatically."
    fi

    if [[ -d "dotfiles" ]]; then
        for file in .zshrc .bash_aliases .vimrc .profile .bashrc; do
            if [[ -f "dotfiles/$file" ]]; then
                cp -f "dotfiles/$file" "$HOME/$file"
                log_info "Applied dotfile $file"
            fi
        done
    fi
}

setup_git() {
    if ! command -v git >/dev/null 2>&1; then
        install_package "git"
    fi

    if ! git config --global user.name >/dev/null 2>&1; then
        read -r -p "Enter your Git username: " git_username || git_username=""
        if [[ -n $git_username ]]; then
            git config --global user.name "$git_username"
            log_success "Git username set to $git_username"
        else
            log_warning "Git username not set."
        fi
    else
        log_info "Git username already configured: $(git config --global user.name)"
    fi

    if ! git config --global user.email >/dev/null 2>&1; then
        read -r -p "Enter your Git email: " git_email || git_email=""
        if [[ -n $git_email ]]; then
            git config --global user.email "$git_email"
            log_success "Git email set to $git_email"
        else
            log_warning "Git email not set."
        fi
    else
        log_info "Git email already configured: $(git config --global user.email)"
    fi

    git config --global init.defaultBranch main >/dev/null 2>&1 || true
}

setup_ssh_key() {
    local ssh_key="$HOME/.ssh/id_rsa"
    if [[ -f $ssh_key ]]; then
        log_info "SSH key already exists at $ssh_key."
        return
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    local email
    email=$(git config --global user.email 2>/dev/null || echo "user@example.com")
    log_info "Generating SSH key for $email..."
    if ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_key" -N "" >/dev/null 2>&1; then
        log_success "SSH key generated at $ssh_key"
        log_info "Public key:\n$(cat "$ssh_key.pub")"
    else
        log_warning "Failed to generate SSH key."
    fi
}

install_vscode() {
    if command -v code >/dev/null 2>&1; then
        log_info "VS Code already installed."
        return
    fi

    case $PACKAGE_MANAGER in
        apt)
            log_info "Installing VS Code via Microsoft apt repo..."
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
            echo "deb [arch=amd64,arm64] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
            sudo apt-get update -y
            sudo apt-get install -y code || log_warning "Failed to install VS Code"
            ;;
        dnf)
            log_info "Installing VS Code via Microsoft rpm repo..."
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc >/dev/null 2>&1
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf install -y code || log_warning "Failed to install VS Code"
            ;;
        pacman)
            log_warning "VS Code install is not automated for pacman-based systems. Install 'code' or 'code-oss' manually."
            ;;
    esac
}

install_chrome() {
    if command -v google-chrome >/dev/null 2>&1; then
        log_info "Google Chrome already installed."
        return
    fi

    case $PACKAGE_MANAGER in
        apt)
            log_info "Installing Google Chrome..."
            if curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -o /tmp/chrome.deb; then
                sudo dpkg -i /tmp/chrome.deb >/dev/null 2>&1 || sudo apt-get install -f -y
                rm -f /tmp/chrome.deb
            else
                log_warning "Failed to download Google Chrome installer."
            fi
            ;;
        dnf|pacman)
            log_warning "Google Chrome installation not automated for this distro. Install manually if needed."
            ;;
    esac
}

install_mongodb() {
    if command -v mongod >/dev/null 2>&1; then
        log_info "MongoDB already installed."
        return
    fi

    if [[ $PACKAGE_MANAGER != "apt" ]]; then
        log_warning "MongoDB installation automated only for apt-based systems."
        return
    fi

    log_info "Configuring MongoDB repository..."
    local repo=""
    local release
    release=$(lsb_release -cs 2>/dev/null || echo "focal")

    case ${OS_ID} in
        ubuntu)
            repo="https://repo.mongodb.org/apt/ubuntu ${release}/mongodb-org/7.0 multiverse"
            ;;
        debian|kali|linuxmint)
            repo="https://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main"
            ;;
        *)
            repo="https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse"
            ;;
    esac

    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg >/dev/null 2>&1
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] $repo" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y mongodb-org && {
        sudo systemctl enable mongod >/dev/null 2>&1 || true
        sudo systemctl start mongod >/dev/null 2>&1 || true
    }
}

install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        log_info "GitHub CLI already installed."
        return
    fi

    case $PACKAGE_MANAGER in
        apt)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt-get update -y
            sudo apt-get install -y gh
            ;;
        dnf)
            sudo dnf install -y 'https://cli.github.com/packages/rpm/gh-cli.repo' >/dev/null 2>&1 || sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo >/dev/null 2>&1
            sudo dnf install -y gh
            ;;
        pacman)
            log_warning "GitHub CLI install not automated for pacman-based systems. Install 'github-cli' manually."
            ;;
    esac
}

install_aws_cli() {
    if command -v aws >/dev/null 2>&1; then
        log_info "AWS CLI already installed."
        return
    fi

    log_info "Installing AWS CLI v2..."
    local tmp_dir=/tmp/awscli
    mkdir -p "$tmp_dir"
    if curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_dir/awscliv2.zip"; then
        unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
        sudo "$tmp_dir/aws/install" >/dev/null 2>&1 || log_warning "AWS CLI installation failed"
        rm -rf "$tmp_dir"
    else
        log_warning "Failed to download AWS CLI."
    fi
}

setup_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "Docker CLI not detected; skipping Docker configuration."
        return
    fi

    sudo systemctl enable docker >/dev/null 2>&1 || true
    sudo systemctl start docker >/dev/null 2>&1 || true
    sudo usermod -aG docker "$USER" >/dev/null 2>&1 || log_warning "Unable to add $USER to docker group automatically."
    log_info "Docker configured. Log out/in to use Docker without sudo."
}

install_hashicorp_tools() {
    case $PACKAGE_MANAGER in
        apt)
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
            sudo apt-get update -y
            install_package "terraform"
            ;;
        dnf)
            install_package "terraform"
            ;;
        pacman)
            log_warning "Terraform install not automated for pacman-based systems. Use community repos/AUR."
            ;;
    esac
}

install_kubectl() {
    case $PACKAGE_MANAGER in
        apt)
            curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg >/dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
            sudo apt-get update -y
            install_package "kubectl"
            ;;
        dnf|pacman)
            install_package "kubectl"
            ;;
    esac
}

run_group_core() {
    install_packages "$(get_group_packages core)"
    setup_directories
    setup_zsh
    setup_git
    setup_ssh_key
}

run_group_development() {
    install_packages "$(get_group_packages development)"
    install_vscode
    install_chrome
    install_mongodb
    install_github_cli
}

run_group_devops() {
    install_packages "$(get_group_packages devops)"
    install_hashicorp_tools
    install_kubectl
    install_aws_cli
    setup_docker
}

run_group_security() {
    install_packages "$(get_group_packages security)"
    install_security_extras
}

run_group_productivity() {
    install_packages "$(get_group_packages productivity)"
}
