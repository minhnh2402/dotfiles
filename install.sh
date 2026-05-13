#!/bin/bash
# ============================================================
# install.sh — Modular Ubuntu Setup for Embedded Developer
# ============================================================
#
# Usage:
#   ./install.sh              # Run all modules
#   ./install.sh --menu       # Interactive menu (pick modules)
#   ./install.sh core zsh     # Run specific modules only
#   ./install.sh --list       # List available modules
#
# Log: ~/install-ubuntu.log
# ============================================================

set -euo pipefail

LOG_FILE="$HOME/install-ubuntu.log"
exec > >(tee -a "$LOG_FILE") 2>&1

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ======================== Helpers ========================

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

step()  { echo -e "\n${G}[✔] $1${N}"; }
warn()  { echo -e "${Y}[!] $1${N}"; }
err()   { echo -e "${R}[✘] $1${N}"; }

check_ubuntu() {
    grep -q "Ubuntu" /etc/os-release 2>/dev/null || { err "Not Ubuntu. Exit."; exit 1; }
}

apt_install() {
    local pkgs=("$@")
    step "Installing ${#pkgs[@]} packages..."
    sudo apt install -y "${pkgs[@]}"
}

# ======================== Modules ========================

mod_core() {
    step "[core] System update + essential packages"
    sudo apt update && sudo apt upgrade -y

    apt_install \
        build-essential make cmake ninja-build ccache gcc g++ gdb \
        python3 python3-pip python3-venv python3-dev python3-setuptools \
        openssh-server openssh-client net-tools iproute2 curl wget \
        git stow unzip zip \
        ca-certificates gnupg lsb-release software-properties-common
}

mod_cli() {
    step "[cli] Terminal utilities"

    apt_install \
        htop btop tree ncdu \
        jq bat ripgrep fd-find fzf tealdeer \
        strace lsof \
        xclip xsel wl-clipboard
}

mod_zsh() {
    step "[zsh] Zsh + Oh My Zsh + plugins + Powerlevel10k"

    sudo apt install -y zsh

    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        warn "Oh My Zsh already installed."
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k"

    # Default shell
    [ "$SHELL" != "$(which zsh)" ] && chsh -s "$(which zsh)"
}

mod_neovim() {
    step "[neovim] Install Neovim"

    sudo apt install -y neovim
    mkdir -p "$HOME/.config/nvim"
}

mod_wezterm() {
    step "[wezterm] Install + set as default terminal"

    if ! command -v wezterm &>/dev/null; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://apt.fury.io/wez/gpg.key \
            | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
            | sudo tee /etc/apt/sources.list.d/wezterm.list
        sudo apt update && sudo apt install -y wezterm

        sudo update-alternatives --install \
            /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
        sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
    else
        warn "WezTerm already installed."
    fi
}

mod_tmux() {
    step "[tmux] Install tmux"

    sudo apt install -y tmux
}

mod_tailscale() {
    step "[tailscale] Install from official repo"

    if ! command -v tailscale &>/dev/null; then
        curl -fsSL https://tailscale.com/install.sh | sh
        warn "Run 'sudo tailscale up' after reboot to login."
    else
        warn "Tailscale already installed: $(tailscale version | head -1)"
    fi
}

mod_esp() {
    step "[esp] ESP-IDF + serial tools + udev rules"

    # Dependencies
    apt_install \
        libffi-dev libssl-dev dfu-util libusb-1.0-0 \
        minicom picocom

    # ESP-IDF
    local ESP_IDF_DIR="$HOME/esp/esp-idf"
    local ESP_IDF_VERSION="v5.4"

    if [ ! -d "$ESP_IDF_DIR" ]; then
        mkdir -p "$HOME/esp"
        git clone --recursive \
            https://github.com/espressif/esp-idf.git \
            -b "$ESP_IDF_VERSION" "$ESP_IDF_DIR"

        cd "$ESP_IDF_DIR" && ./install.sh all && cd "$HOME"
    else
        warn "ESP-IDF already exists at $ESP_IDF_DIR"
    fi

    # Alias — add to .bashrc as fallback (.zshrc managed via stow)
    local ALIAS_LINE='alias get_idf=". $HOME/esp/esp-idf/export.sh"'
    if [ -f "$HOME/.bashrc" ] && ! grep -q "get_idf" "$HOME/.bashrc"; then
        printf '\n# ESP-IDF\n%s\n' "$ALIAS_LINE" >> "$HOME/.bashrc"
    fi

    # dialout group
    if ! groups "$USER" | grep -q "dialout"; then
        sudo usermod -aG dialout "$USER"
        warn "Added $USER to dialout. Logout/login required."
    fi

    # Udev rules
    local UDEV_FILE="/etc/udev/rules.d/99-usb-serial.rules"
    if [ ! -f "$UDEV_FILE" ]; then
        sudo tee "$UDEV_FILE" > /dev/null << 'EOF'
# CP210x (Silicon Labs — ESP32 DevKit)
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
# CH340/CH341 (ESP clones)
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
# FTDI (FT232, FT2232)
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE="0666"
# Raspberry Pi Pico (RP2040)
SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", MODE="0666"
EOF
        sudo udevadm control --reload-rules && sudo udevadm trigger
    fi
}

mod_rasp() {
    step "[rasp] Raspberry Pi cross-compile + tools"

    apt_install \
        gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        rsync sshpass
}

mod_nvidia() {
    step "[nvidia] Install NVIDIA driver"

    if ! nvidia-smi &>/dev/null; then
        sudo ubuntu-drivers autoinstall
        warn "NVIDIA driver installed. REBOOT required."
    else
        warn "NVIDIA OK: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
    fi
}

mod_fonts() {
    step "[fonts] Coding Nerd Fonts"

    local FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    # Nerd Font versions (patched with icons for terminal/neovim)
    local NERD_FONTS=(
        "JetBrainsMono"       # Default — great x-height, ligatures
        "FiraCode"            # Most popular — extensive ligatures
        "Inconsolata"         # Clean, classic Google font
        "Hack"                # Excellent Unicode coverage
        "CascadiaCode"        # Microsoft — cursive italic variant
        "SourceCodePro"       # Adobe — 7 weights, very readable
        "UbuntuMono"          # Matches Ubuntu system aesthetic
        "Iosevka"             # Narrow — fit more code per line
    )

    local BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

    for font in "${NERD_FONTS[@]}"; do
        if ! fc-list | grep -qi "${font}.*Nerd"; then
            step "Downloading ${font} Nerd Font..."
            wget -qO "/tmp/${font}.zip" "${BASE_URL}/${font}.zip"
            unzip -o "/tmp/${font}.zip" -d "$FONT_DIR" >/dev/null 2>&1
            rm -f "/tmp/${font}.zip"
        else
            warn "${font} Nerd Font already installed."
        fi
    done

    fc-cache -f "$FONT_DIR"
    step "All fonts installed. Set your preferred font in WezTerm config."
}

mod_git() {
    step "[git] Configure Git"

    if [ -z "$(git config --global user.name)" ]; then
        read -rp "Git username: " git_name
        read -rp "Git email: " git_email
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global core.editor nvim
    else
        warn "Git already configured: $(git config --global user.name)"
    fi
}

mod_stow() {
    step "[stow] Link dotfiles"

    local STOW_PKGS=(zsh nvim wezterm git tmux ssh scripts)

    cd "$DOTFILES_DIR"
    for pkg in "${STOW_PKGS[@]}"; do
        if [ -d "$DOTFILES_DIR/$pkg" ]; then
            step "Linking $pkg..."
            stow --adopt -t "$HOME" "$pkg" 2>/dev/null || \
            stow -t "$HOME" "$pkg"
        fi
    done
    cd "$HOME"
}

mod_cleanup() {
    step "[cleanup] Remove unused packages"
    sudo apt autoremove -y && sudo apt autoclean -y
}

# ======================== Module registry ========================

ALL_MODULES=(
    core
    cli
    zsh
    neovim
    wezterm
    tmux
    tailscale
    esp
    rasp
    nvidia
    fonts
    git
    stow
    cleanup
)

# ======================== Module descriptions ========================

declare -A MOD_DESC=(
    [core]="System update, build tools, python, ssh, git, stow"
    [cli]="Terminal utils (ripgrep, fzf, bat, xclip, tealdeer...)"
    [zsh]="Zsh + Oh My Zsh + plugins + Powerlevel10k"
    [neovim]="Neovim editor"
    [wezterm]="WezTerm terminal + set as default"
    [tmux]="Tmux multiplexer"
    [tailscale]="Tailscale VPN (official repo)"
    [esp]="ESP-IDF + serial tools + udev rules"
    [rasp]="Raspberry Pi cross-compilers + tools"
    [nvidia]="NVIDIA driver (auto-detect)"
    [fonts]="Coding Nerd Fonts (JetBrains, Fira, Inconsolata, Hack...)"
    [git]="Git global config (name, email, editor)"
    [stow]="Symlink dotfiles via GNU Stow"
    [cleanup]="apt autoremove + autoclean"
)

list_modules() {
    echo ""
    echo "Available modules:"
    echo ""
    for mod in "${ALL_MODULES[@]}"; do
        printf "  %-12s %s\n" "$mod" "${MOD_DESC[$mod]}"
    done
    echo ""
    echo "Usage:"
    echo "  ./install.sh              # Run all"
    echo "  ./install.sh --menu       # Interactive menu"
    echo "  ./install.sh core cli zsh # Run specific modules"
    echo ""
}

# ======================== Interactive menu ========================

show_menu() {
    local total=${#ALL_MODULES[@]}
    local selected=()
    local cursor=0
    local mod desc check color count key rest i

    # All selected by default
    for ((i=0; i<total; i++)); do
        selected+=("1")
    done

    # Hide cursor
    tput civis 2>/dev/null || true

    # Restore cursor on exit/error
    trap 'tput cnorm 2>/dev/null; echo' RETURN

    while true; do
        # Clear and draw
        tput clear 2>/dev/null || clear

        echo -e "${G}============================================================${N}"
        echo -e "${G} Ubuntu Setup — Select modules to install${N}"
        echo -e "${G}============================================================${N}"
        echo ""
        echo -e " ${Y}↑↓${N} Move   ${Y}Space${N} Toggle   ${Y}a${N} All   ${Y}n${N} None   ${Y}Enter${N} Confirm   ${Y}q${N} Quit"
        echo ""

        for ((i=0; i<total; i++)); do
            mod="${ALL_MODULES[$i]}"
            desc="${MOD_DESC[$mod]}"
            check=" "
            color=""

            if [ "${selected[$i]}" = "1" ]; then
                check="✔"
                color="${G}"
            fi

            if [ "$i" -eq "$cursor" ]; then
                echo -e "  ${color}► [${check}] $(printf '%-12s' "$mod") ${desc}${N}"
            else
                echo -e "    ${color}[${check}] $(printf '%-12s' "$mod") ${desc}${N}"
            fi
        done

        # Count selected
        count=0
        for i in "${selected[@]}"; do
            [ "$i" = "1" ] && count=$((count + 1))
        done

        echo ""
        echo -e " ${Y}${count}/${total}${N} modules selected"

        # Read key
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')
                read -rsn2 rest
                case "$rest" in
                    '[A')
                        if [ "$cursor" -gt 0 ]; then
                            cursor=$((cursor - 1))
                        fi
                        ;;
                    '[B')
                        if [ "$cursor" -lt $((total - 1)) ]; then
                            cursor=$((cursor + 1))
                        fi
                        ;;
                esac
                ;;
            ' ')
                if [ "${selected[$cursor]}" = "1" ]; then
                    selected[$cursor]="0"
                else
                    selected[$cursor]="1"
                fi
                ;;
            'a')
                for ((i=0; i<total; i++)); do
                    selected[$i]="1"
                done
                ;;
            'n')
                for ((i=0; i<total; i++)); do
                    selected[$i]="0"
                done
                ;;
            '')
                break
                ;;
            'q')
                echo ""
                warn "Cancelled."
                tput cnorm 2>/dev/null || true
                exit 0
                ;;
        esac
    done

    # Restore cursor
    tput cnorm 2>/dev/null || true

    # Build selected modules list
    MENU_SELECTED=()
    for ((i=0; i<total; i++)); do
        if [ "${selected[$i]}" = "1" ]; then
            MENU_SELECTED+=("${ALL_MODULES[$i]}")
        fi
    done

    if [ ${#MENU_SELECTED[@]} -eq 0 ]; then
        warn "No modules selected. Exit."
        exit 0
    fi

    echo ""
    step "Selected: ${MENU_SELECTED[*]}"
    echo ""
    read -rp "Press Enter to start, Ctrl+C to cancel..."
}

# ======================== Main ========================

main() {
    check_ubuntu

    echo "============================================================"
    echo " Ubuntu Setup — Embedded Developer (modular)"
    echo " Started: $(date)"
    echo "============================================================"

    local modules=("$@")

    # No args = run all
    if [ ${#modules[@]} -eq 0 ]; then
        modules=("${ALL_MODULES[@]}")
    fi

    # Run selected modules
    for mod in "${modules[@]}"; do
        if declare -f "mod_$mod" > /dev/null; then
            mod_"$mod"
        else
            err "Unknown module: $mod"
            list_modules
            exit 1
        fi
    done

    # Summary
    echo ""
    echo "============================================================"
    echo -e "${G} DONE!${N}"
    echo "============================================================"
    echo ""
    echo " Modules executed: ${modules[*]}"
    echo ""
    echo " TODO after reboot:"
    echo "   1. Reboot (NVIDIA driver + dialout group)"
    echo "   2. Run 'p10k configure' in new terminal"
    echo "   3. Run 'sudo tailscale up' to login"
    echo "   4. Type 'get_idf' to load ESP-IDF when needed"
    echo ""
    echo " Log: $LOG_FILE"
    echo "============================================================"
}

# Handle flags
case "${1:-}" in
    --list)
        list_modules
        exit 0
        ;;
    --menu)
        show_menu
        main "${MENU_SELECTED[@]}"
        ;;
    *)
        main "$@"
        ;;
esac
