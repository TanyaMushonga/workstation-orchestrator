#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling function
handle_error() {
    log_error "An error occurred in function: $1"
    log_info "Continuing with next step..."
}

# Check if running on supported system
check_system() {
    log_info "Checking system compatibility..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_info "Detected OS: $NAME $VERSION"
        
        case $ID in
            kali|debian|ubuntu)
                log_success "System is compatible"
                ;;
            *)
                log_warning "System may not be fully compatible. Proceeding anyway..."
                ;;
        esac
    else
        log_warning "Cannot detect OS. Proceeding anyway..."
    fi
}

# Update system packages
update_system() {
    log_info "🔄 Updating system packages..."
    
    if sudo apt update && sudo apt upgrade -y; then
        log_success "System updated successfully"
    else
        handle_error "update_system"
        return 1
    fi
}

# Install packages with error handling
install_packages() {
    log_info "📦 Installing core packages..."
    
    # Core essential packages that should always be available
    ESSENTIAL_PACKAGES=(
        "git"
        "curl" 
        "wget"
        "vim"
        "htop"
        "build-essential"
        "python3"
        "python3-pip"
        "python3-venv"
        "nodejs"
        "npm"
        "unzip"
        "zip"
        "tree"
        "jq"
        "net-tools"
        "ca-certificates"
        "gnupg"
        "software-properties-common"
        "apt-transport-https"
    )
    
    # Install essential packages one by one
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>/dev/null; then
            log_success "$package installed"
        else
            log_warning "Failed to install $package, skipping..."
        fi
    done
    
    # Optional packages that might not be available on all systems
    OPTIONAL_PACKAGES=(
        "openjdk-21-jdk"
        "docker.io"
        "docker-compose"
        "postgresql"
        "postgresql-contrib"
        "redis-server"
        "sqlite3"
        "vlc"
        "gimp"
        "libreoffice"
        "neofetch"
        "tmux"
        "zsh"
    )
    
    log_info "Installing optional packages..."
    for package in "${OPTIONAL_PACKAGES[@]}"; do
        if sudo apt install -y "$package" 2>/dev/null; then
            log_success "$package installed"
        else
            log_warning "$package not available or failed to install, skipping..."
        fi
    done
}

# Install Kali-specific security tools
install_security_tools() {
    log_info "🔐 Installing cybersecurity tools..."
    
    # Check if we're on Kali (has Kali repos)
    if command -v kali-tweaks >/dev/null 2>&1 || grep -q "kali" /etc/os-release 2>/dev/null; then
        log_info "Kali Linux detected, installing security tools..."
        
        SECURITY_TOOLS=(
            "nmap"
            "wireshark"
            "metasploit-framework"
            "sqlmap" 
            "hydra"
            "john"
            "hashcat"
            "gobuster"
            "nikto"
            "netcat-traditional"
            "aircrack-ng"
        )
        
        for tool in "${SECURITY_TOOLS[@]}"; do
            if sudo apt install -y "$tool" 2>/dev/null; then
                log_success "$tool installed"
            else
                log_warning "$tool not available, skipping..."
            fi
        done
    else
        log_warning "Not on Kali Linux, skipping specialized security tools"
        # Install basic network tools available on most systems
        sudo apt install -y nmap netcat-openbsd 2>/dev/null || true
    fi
}

# Install VS Code
install_vscode() {
    log_info "💻 Installing VS Code..."
    
    if command -v code >/dev/null 2>&1; then
        log_warning "VS Code already installed, skipping..."
        return 0
    fi
    
    # Download and install Microsoft GPG key
    if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg 2>/dev/null; then
        sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/ 2>/dev/null || {
            log_warning "Failed to install Microsoft GPG key"
            return 1
        }
        
        # Add VS Code repository
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        
        if sudo apt update && sudo apt install -y code; then
            log_success "VS Code installed successfully"
        else
            log_warning "Failed to install VS Code"
            return 1
        fi
    else
        log_warning "Failed to download Microsoft GPG key, skipping VS Code"
        return 1
    fi
}

# Install Google Chrome
install_chrome() {
    log_info "🌐 Installing Google Chrome..."
    
    if command -v google-chrome >/dev/null 2>&1; then
        log_warning "Google Chrome already installed, skipping..."
        return 0
    fi
    
    # Download Chrome directly
    if wget -q -O /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"; then
        if sudo dpkg -i /tmp/chrome.deb 2>/dev/null || sudo apt --fix-broken install -y; then
            log_success "Google Chrome installed successfully"
            rm -f /tmp/chrome.deb
        else
            log_warning "Failed to install Google Chrome"
            rm -f /tmp/chrome.deb
            return 1
        fi
    else
        log_warning "Failed to download Google Chrome"
        return 1
    fi
}

# Install MongoDB
install_mongodb() {
    log_info "🍃 Installing MongoDB..."
    
    if command -v mongod >/dev/null 2>&1; then
        log_warning "MongoDB already installed, skipping..."
        return 0
    fi
    
    # Import MongoDB public GPG Key
    if wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add - 2>/dev/null; then
        # Detect Ubuntu/Debian version for correct repo
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu)
                    MONGODB_REPO="https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse"
                    ;;
                debian|kali)
                    MONGODB_REPO="https://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main"
                    ;;
                *)
                    MONGODB_REPO="https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse"
                    ;;
            esac
        else
            MONGODB_REPO="https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse"
        fi
        
        echo "deb [ arch=amd64,arm64 ] $MONGODB_REPO" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >/dev/null
        
        if sudo apt update && sudo apt install -y mongodb-org; then
            sudo systemctl enable mongod 2>/dev/null || true
            sudo systemctl start mongod 2>/dev/null || true
            log_success "MongoDB installed successfully"
        else
            log_warning "Failed to install MongoDB from repository"
            return 1
        fi
    else
        log_warning "Failed to add MongoDB GPG key, skipping..."
        return 1
    fi
}

# Install GitHub CLI
install_github_cli() {
    log_info "🐙 Installing GitHub CLI..."
    
    if command -v gh >/dev/null 2>&1; then
        log_warning "GitHub CLI already installed, skipping..."
        return 0
    fi
    
    if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null; then
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        
        if sudo apt update && sudo apt install -y gh; then
            log_success "GitHub CLI installed successfully"
        else
            log_warning "Failed to install GitHub CLI"
            return 1
        fi
    else
        log_warning "Failed to install GitHub CLI"
        return 1
    fi
}

# Install AWS CLI
install_aws_cli() {
    log_info "☁️ Installing AWS CLI..."
    
    if command -v aws >/dev/null 2>&1; then
        log_warning "AWS CLI already installed, skipping..."
        return 0
    fi
    
    if curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"; then
        cd /tmp
        unzip -q awscliv2.zip
        if sudo ./aws/install 2>/dev/null; then
            log_success "AWS CLI installed successfully"
            rm -rf /tmp/aws* 2>/dev/null
        else
            log_warning "Failed to install AWS CLI"
            rm -rf /tmp/aws* 2>/dev/null
            return 1
        fi
    else
        log_warning "Failed to download AWS CLI"
        return 1
    fi
}

# Install Snap packages
install_snap_packages() {
    log_info "📦 Installing Snap packages..."
    
    # Enable snapd if not running
    if command -v snap >/dev/null 2>&1; then
        sudo systemctl enable snapd 2>/dev/null || true
        sudo systemctl start snapd 2>/dev/null || true
        
        SNAP_PACKAGES=("code --classic" "android-studio --classic" "postman" "discord")
        
        for package in "${SNAP_PACKAGES[@]}"; do
            log_info "Installing snap package: $package"
            if sudo snap install $package 2>/dev/null; then
                log_success "Snap package $package installed"
            else
                log_warning "Failed to install snap package: $package"
            fi
        done
    else
        log_warning "Snapd not available, skipping snap packages"
    fi
}

# Setup Oh-My-Zsh
setup_zsh() {
    log_info "⚙️ Setting up Zsh and Oh-My-Zsh..."
    
    # Install zsh if not present
    if ! command -v zsh >/dev/null 2>&1; then
        sudo apt install -y zsh 2>/dev/null || {
            log_warning "Failed to install zsh"
            return 1
        }
    fi
    
    # Install Oh-My-Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
            log_success "Oh-My-Zsh installed successfully"
        else
            log_warning "Failed to install Oh-My-Zsh"
            return 1
        fi
    fi
    
    # Change default shell to zsh (user will need to logout/login)
    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || log_warning "Could not change default shell to zsh"
    fi
}

# Setup development environment
setup_dev_environment() {
    log_info "🛠️ Setting up development environment..."
    
    # Create directories
    log_info "Creating development directories..."
    mkdir -p "$HOME/Development"/{projects,tools,scripts} 2>/dev/null
    mkdir -p "$HOME/Android/Sdk" 2>/dev/null
    mkdir -p "$HOME/.local/bin" 2>/dev/null
    
    # Copy dotfiles if they exist
    if [ -d "dotfiles" ]; then
        log_info "Copying dotfiles..."
        cp -f dotfiles/.zshrc "$HOME/" 2>/dev/null && log_success "Copied .zshrc" || log_warning "Failed to copy .zshrc"
        cp -f dotfiles/.bash_aliases "$HOME/" 2>/dev/null && log_success "Copied .bash_aliases" || log_warning "Failed to copy .bash_aliases"
        cp -f dotfiles/.vimrc "$HOME/" 2>/dev/null && log_success "Copied .vimrc" || log_warning "Failed to copy .vimrc"
        cp -f dotfiles/.profile "$HOME/" 2>/dev/null && log_success "Copied .profile" || log_warning "Failed to copy .profile"
        cp -f dotfiles/.bashrc "$HOME/" 2>/dev/null && log_success "Copied .bashrc" || log_warning "Failed to copy .bashrc"
    else
        log_warning "Dotfiles directory not found, skipping..."
    fi
    
    # Install Python development tools
    log_info "Installing Python development tools..."
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user --upgrade pip setuptools wheel 2>/dev/null || log_warning "Failed to upgrade pip"
        pip3 install --user virtualenv black flake8 requests poetry jupyter ipython 2>/dev/null || log_warning "Some Python packages failed to install"
        log_success "Python tools installed"
    fi
    
    # Install NVM for Node.js
    log_info "Installing NVM..."
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh 2>/dev/null | bash; then
        log_success "NVM installed successfully"
    else
        log_warning "Failed to install NVM"
    fi
}

# Setup Docker permissions
setup_docker() {
    log_info "🐳 Setting up Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        # Add user to docker group
        sudo usermod -aG docker "$USER" 2>/dev/null && log_success "Added user to docker group" || log_warning "Failed to add user to docker group"
        
        # Enable and start docker service
        sudo systemctl enable docker 2>/dev/null || true
        sudo systemctl start docker 2>/dev/null || true
        
        log_info "Docker setup complete. You may need to logout and login for group changes to take effect."
    else
        log_warning "Docker not installed, skipping Docker setup"
    fi
}

# Setup Git configuration
setup_git() {
    log_info "📝 Setting up Git configuration..."
    
    # Check if git is configured
    if ! git config --global user.name >/dev/null 2>&1; then
        echo "Please enter your Git username:"
        read -r git_username
        git config --global user.name "$git_username"
        log_success "Git username set to: $git_username"
    else
        log_info "Git username already configured: $(git config --global user.name)"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        echo "Please enter your Git email:"
        read -r git_email
        git config --global user.email "$git_email"
        log_success "Git email set to: $git_email"
    else
        log_info "Git email already configured: $(git config --global user.email)"
    fi
    
    # Set default branch to main
    git config --global init.defaultBranch main 2>/dev/null || true
}

# Generate SSH key
setup_ssh_key() {
    log_info "🔑 Setting up SSH key..."
    
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        # Get email for SSH key
        git_email=$(git config --global user.email 2>/dev/null || echo "user@example.com")
        
        log_info "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -C "$git_email" -f "$HOME/.ssh/id_rsa" -N "" 2>/dev/null && {
            log_success "SSH key generated successfully"
            echo "Your SSH public key:"
            cat "$HOME/.ssh/id_rsa.pub"
            echo ""
            log_info "Add this key to your GitHub/GitLab account"
        } || log_warning "Failed to generate SSH key"
    else
        log_info "SSH key already exists"
    fi
}

# Main installation function
main() {
    echo "🚀 Starting Kali Workstation Setup..."
    echo "======================================"
    
    # Run setup functions with error handling
    check_system || true
    update_system || handle_error "update_system"
    install_packages || handle_error "install_packages"
    install_security_tools || handle_error "install_security_tools"
    install_vscode || handle_error "install_vscode"
    install_chrome || handle_error "install_chrome"
    install_mongodb || handle_error "install_mongodb"
    install_github_cli || handle_error "install_github_cli"
    install_aws_cli || handle_error "install_aws_cli"
    install_snap_packages || handle_error "install_snap_packages"
    setup_zsh || handle_error "setup_zsh"
    setup_dev_environment || handle_error "setup_dev_environment"
    setup_docker || handle_error "setup_docker"
    setup_git || handle_error "setup_git"
    setup_ssh_key || handle_error "setup_ssh_key"
    
    echo ""
    log_success "✅ Workstation setup completed!"
    echo ""
    log_info "📋 Next Steps:"
    echo "   1. Reboot your system: sudo reboot"
    echo "   2. Configure Android Studio SDK path: ~/Android/Sdk"
    echo "   3. Sign in to GitHub CLI: gh auth login"
    echo "   4. Configure AWS CLI: aws configure"
    echo "   5. Add your SSH key to GitHub/GitLab"
    echo "   6. Logout and login to apply Docker group changes"
    echo ""
    log_info "🎉 Enjoy your new development workstation!"
}

# Run main function
main "$@"
