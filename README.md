# Dotfiles — Embedded Developer Setup

Ubuntu 26.04 LTS setup for ESP32/ESP8266 + Raspberry Pi development.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/<username>/dotfiles.git ~/dotfiles

# 2. Install packages
cd ~/dotfiles
chmod +x install.sh
./install.sh

# 3. Reboot
sudo reboot
```

`install.sh` handles everything: packages, WezTerm, Zsh + Oh My Zsh, Neovim, ESP-IDF, NVIDIA driver, fonts, and links all config files via `stow`.

## Structure

```
~/dotfiles/
├── install.sh                          # Package installer
├── README.md
├── zsh/
│   └── .zshrc                          # → ~/.zshrc
├── nvim/
│   └── .config/nvim/
│       └── init.lua                    # → ~/.config/nvim/init.lua
├── wezterm/
│   └── .config/wezterm/
│       └── wezterm.lua                 # → ~/.config/wezterm/wezterm.lua
├── git/
│   └── .gitconfig                      # → ~/.gitconfig
└── tmux/
    └── .tmux.conf                      # → ~/.tmux.conf
```

Each folder mirrors `$HOME`. Running `stow <folder>` creates symlinks.

## Manual Stow Commands

```bash
cd ~/dotfiles

# Link everything
stow zsh nvim wezterm git tmux

# Link one config
stow nvim

# Unlink one config
stow -D nvim

# Re-link after changes
stow -R nvim
```

## Add New Config

Example: adding `starship` prompt config:

```bash
mkdir -p ~/dotfiles/starship/.config
cp ~/.config/starship.toml ~/dotfiles/starship/.config/
cd ~/dotfiles && stow starship
```

Then update `install.sh` section 6 — add `starship` to the stow loop.

## Add New Packages

Open `install.sh`, find the right array, add package name:

```bash
UTIL_PKGS=(
    ...
    new-package    # ← add here
)
```

Run `./install.sh` again — it skips what's already installed.
