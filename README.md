# Workstation Setup Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/platform-linux-orange?logo=linux)](#supported-platforms)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-black?logo=apple)](#supported-platforms)
[![Platform: Windows](https://img.shields.io/badge/platform-windows-blue?logo=windows)](#supported-platforms)

> **One command to bootstrap a consistent developer, DevOps, and security workstation across Linux, macOS, and Windows.**

## Table of Contents

1. [Supported Platforms](#supported-platforms)
2. [Tool Groups](#tool-groups)
3. [Repository Layout](#repository-layout)
4. [Quick Start](#quick-start)
5. [What the Installers Do](#what-the-installers-do)
6. [Project Highlights](#project-highlights)
7. [Post-Install Checklist](#post-install-checklist)
8. [Customising](#customising)
9. [Requirements](#requirements)
10. [Contributing](#contributing)
11. [Support & Feedback](#support--feedback)
12. [License](#license)

---

## Supported Platforms

- **Linux** (`install.sh` → `scripts/linux/install.sh`)
  - Debian, Ubuntu, Kali, Linux Mint, Pop!\_OS, Elementary, Zorin
  - Fedora, RHEL, CentOS Stream, Rocky, AlmaLinux
  - Arch, Manjaro, EndeavourOS, and other pacman-based distributions
- **macOS** (`install.sh` → `scripts/macos/install.sh`)
  - macOS 12 or newer with Homebrew available on PATH and Bash ≥ 4
- **Windows** (`install.ps1` → `scripts/windows/install.ps1`)
  - Windows 10 21H2+ / Windows 11 with winget (run in an elevated PowerShell session)

The entry-point scripts detect your operating system and forward to the OS-specific installer automatically.

---

## Tool Groups

Choose the bundles you want at install time—mix and match or install everything.

| Group          | Description                                         | Sample Tools                                                            |
| -------------- | --------------------------------------------------- | ----------------------------------------------------------------------- |
| `core`         | Shell enhancements, CLI basics, dotfiles, Git setup | git, curl, zsh/Oh My Zsh, Windows Terminal, Oh My Posh                  |
| `development`  | Languages, databases, IDEs, API clients             | Python, Node.js, Java 21, Go, Rust, VS Code, JetBrains Toolbox, Postman |
| `devops`       | Containers, cloud CLIs, infrastructure-as-code      | Docker, kubectl, Terraform, AWS CLI, Azure CLI, Google Cloud SDK        |
| `security`     | Offensive security & network tooling                | Nmap, Wireshark, Metasploit (Kali), Burp Suite, hashcat                 |
| `productivity` | Browsers, office suite, media, communications       | Chrome, Brave, LibreOffice, Slack, Discord, OBS, VLC                    |

Enter `all` to install every group. Pressing Enter at the prompt installs the default `core development` combination.

---

## Repository Layout

```
.
├── install.sh                  # OS dispatcher for Linux/macOS
├── install.ps1                 # OS dispatcher for Windows
├── scripts/
│   ├── linux/
│   │   ├── install.sh
│   │   ├── groups.sh
│   │   ├── actions.sh
│   │   └── lib/
│   ├── macos/
│   │   ├── install.sh
│   │   ├── groups.sh
│   │   └── lib/
│   └── windows/
│       └── install.ps1
├── dotfiles/                   # Optional shell/editor configs copied during setup
├── packages.txt                # Legacy package manifest (Linux reference)
└── LICENSE
```

---

## Quick Start

### Linux

```bash
git clone https://github.com/TanyaMushonga/workstation-kali.git
cd workstation-kali
chmod +x install.sh
./install.sh
```

The script detects your distribution, updates package indexes, and prompts for tool groups.

### macOS

```bash
# Optional if you're using the system Bash (3.x)
brew install bash

/usr/local/bin/bash install.sh
```

Requirements: Homebrew installed and accessible on PATH. The installer verifies Bash 4+, updates Homebrew, and installs the selected formulae and casks.

### Windows

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope Process
cd path\to\workstation-kali
./install.ps1 -Groups "core,development,devops"
```

Omit `-Groups` to accept defaults or pass `all` for the full stack.

---

## What the Installers Do

1. Detect your OS/distro and choose the native package manager (`apt`, `dnf`, `pacman`, `Homebrew`, `winget`).
2. Update package indexes to ensure the newest versions are available.
3. Prompt for tool groups and install the selected bundles.
4. Set up languages, SDKs, databases, and IDEs tailored to the platform.
5. Configure DevOps tooling such as Docker, Kubernetes utilities, Terraform, and cloud CLIs.
6. Apply dotfiles and shell customisations (Oh My Zsh / Oh My Posh).
7. Scaffold development directories at `~/Development/{projects,tools,scripts}`.
8. Offer Git configuration prompts and optional SSH key generation (Linux/macOS).
9. Summarise next steps for authentication, Docker login, and environment validation.

---

## Project Highlights

- 🔁 **Idempotent installs** – safe to re-run when refreshing existing machines.
- 🧰 **Curated bundles** – consistent tooling across core dev, DevOps, security, and productivity use-cases.
- 🧪 **Distro-aware logic** – chooses the right package identifiers for `apt`, `dnf`, `pacman`, Homebrew, and winget.
- 🗃️ **Modular architecture** – each OS ships its own `groups.sh`, helper library, and post-install routines for easy extension.
- 🧑‍💻 **Dotfiles friendly** – automatically syncs files from `dotfiles/` and applies shell customisations (Oh My Zsh/Oh My Posh).
- 🌐 **Cloud-ready** – installs AWS, Azure, and Google Cloud CLIs with optional Kubernetes helpers out of the box.

## Post-Install Checklist

- Restart your terminal session. Linux users should log out/in to pick up docker group membership.
- Launch Docker Desktop once on macOS/Windows to finish setup.
- Run `gh auth login`, `aws configure`, `az login`, and `gcloud init` as required.
- Add generated SSH keys to your Git hosting provider.
- On macOS, run `brew doctor` for a quick sanity check.

---

## Customising

- Adjust group memberships in `scripts/*/groups.sh`.
- Add or modify post-install hooks in `scripts/linux/actions.sh`.
- Drop extra dotfiles into `dotfiles/` for automatic syncing.
- Use `packages.txt` as a reference or seed for bespoke Linux builds.

---

## Requirements

- **Linux**: Supported distro, sudo privileges, and internet access.
- **macOS**: Homebrew installed and Bash ≥ 4 (installable via `brew install bash`).
- **Windows**: Administrator PowerShell session with winget available.

---

## Contributing

We welcome contributions of all sizes—from typo fixes and package suggestions to new automation modules.

1. **Open an issue first** for feature ideas, bug reports, or distro-specific package fixes. This helps us discuss scope before you invest time.
2. **Fork the repository** and create a feature branch (`git checkout -b feature/my-enhancement`).
3. **Test on your platform**: run the relevant installer locally and ensure shellcheck/PowerShell linting passes if you have them available.
4. **Document changes**: update the README or inline comments for new behaviour, and extend group descriptions or post-install notes where appropriate.
5. **Submit a pull request** referencing the issue. Fill out the PR template, include screenshots or terminal transcripts when useful, and describe validation steps.

> New to the project? Check the Issues tab for **good first issues** or **help wanted** labels.

### Development Tips

- Use the modular structure under `scripts/<os>/` to keep platform-specific logic isolated.
- Keep package identifiers alphabetised within each group for readability.
- Prefer native package managers before curl/bash installers unless no package exists.
- When adding secrets-sensitive tools, document any manual authentication needed post-install.

---

## Support & Feedback

- **Bug reports / Feature requests**: [Open an issue](https://github.com/TanyaMushonga/workstation-kali/issues/new/choose).
- **Questions & discussion**: Start a GitHub Discussion or comment on the relevant issue/PR.
- **Security disclosures**: Email the maintainer (see Git history) rather than opening a public issue.

If you ship a cool workstation profile using this toolkit, share a link—we love highlighting community setups!

---

## License

Released under the [MIT License](LICENSE). Contributions are welcome!
