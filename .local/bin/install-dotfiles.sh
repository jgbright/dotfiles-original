#!/usr/bin/env bash

# Setup dotfiles.

set -e

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root." >&2
    exit 1
fi

log() {
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "${timestamp}: ${1}"
}

apt_get_update() {
    if [ -z "$(ls -A /var/lib/apt/lists)" ]; then
        if [ "$(command -v sudo)" ]; then
            log "Updating apt lists..."
            sudo apt-get update
        else
            # Will this work?
            log "Updating apt lists without sudo..."
            apt-get update
        fi

        log "Updated apt lists."
    fi
}

apt_remove_lists() {
    sudo rm -rf /var/lib/apt/lists/*
}

cleanup() {
    log "Cleaning up..."
    apt_remove_lists
    log "Cleaned up."
}

install_sudo() {
    if command -v sudo &>/dev/null; then
        log "Sudo already installed."
    else
        log "Installing sudo..."

        apt_get_update
        apt-get install -y sudo
        apt_remove_lists

        log "Installed sudo."
    fi
}

install_git() {
    if command -v git &>/dev/null; then
        log "Git already installed."
    else
        log "Installing git..."

        apt_get_update
        sudo apt-get install -y git-all

        log "Installed git."
    fi
}

install_dotfiles_repo() {
    pushd ~ &>/dev/null

    if git rev-parse --git-dir >/dev/null 2>&1; then
        log "Home directory is already a git repository.  Runnint git pull..."
        git pull
        log "Ran git pull."
    else
        log "Initializing dotfiles repository in home dir..."
        git init
        git remote add origin git@github.com:jgbright/dotfiles
        git fetch
        git checkout -f main
        log "Initialized dotfiles repository in home dir."
    fi

    popd
}

install_az() {
	if command -v qz &>/dev/null; then
		log "already"
	else
		curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
	fi
}

install_pwsh() {
    if command -v pwsh &>/dev/null; then
        log "Powershell already installed."
    else
        log "Installing powershell..."

        # https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.3
        apt_get_update
        sudo apt-get install -y wget apt-transport-https software-properties-common
        wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
        sudo dpkg -i packages-microsoft-prod.deb
        sudo apt-get update
        sudo apt-get install -y powershell

        log "Installed powershell."
    fi
}

install_lazygit() {
    if command -v lazygit &>/dev/null; then
        log "Lazygit already installed."
    else
        log "Installing lazygit..."

        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        pushd /tmp
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm -f lazygit,lazygit.tar.gz
        popd

        log "Installed lazygit."
    fi
}

install_lazydocker() {
    if command -v lazydocker &>/dev/null; then
        log "Lazydocker already installed."
    else
        log "Installing lazydocker..."

        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/bin bash

        log "Installed lazydocker."
    fi
}

install_dive() {
    if command -v dive &>/dev/null; then
        log "Dive already installed."
    else
        log "Installing dive..."

        pushd /tmp
        wget https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
        sudo apt install ./dive_0.9.2_linux_amd64.deb
        rm ./dive_0.9.2_linux_amd64.deb
        popd

        log "Installed dive."
    fi
}

install_k9s() {
    if command -v k9s &>/dev/null; then
        log "K9s already installed."
    else
        log "Installing k9s..."

        curl -sS https://webinstall.dev/k9s | bash

        log "Installed k9s."
    fi
}

main() {
    log "Installing dotfiles..."

    install_sudo
    install_git
    install_dotfiles_repo
    install_pwsh
    install_az
    install_lazygit
    install_lazydocker
    install_dive
    install_k9s

    cleanup

    log "Installed dotfiles."
}

main
