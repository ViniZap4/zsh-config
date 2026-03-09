#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect OS ──────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

# ── Detect package manager ─────────────────────────────────────────
detect_pm() {
  if command -v brew &>/dev/null; then echo "brew"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v zypper &>/dev/null; then echo "zypper"
  elif command -v nix-env &>/dev/null; then echo "nix"
  else echo "unknown"
  fi
}

OS=$(detect_os)
PM=$(detect_pm)

echo "→ Detected OS: $OS, Package Manager: $PM"

# ── Install zsh ───────────────────────────────────────────────────
install_zsh() {
  if command -v zsh &>/dev/null; then
    echo "→ zsh already installed"
    return
  fi

  echo "→ Installing zsh..."
  case "$PM" in
    brew)   brew install zsh 2>/dev/null || true ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y zsh curl 2>/dev/null || true ;;
    pacman) sudo pacman -S --noconfirm --needed zsh curl 2>/dev/null || true ;;
    dnf)    sudo dnf install -y zsh curl 2>/dev/null || true ;;
    zypper) sudo zypper install -y zsh curl 2>/dev/null || true ;;
  esac
}

install_zsh

# ── Install Oh My Zsh ────────────────────────────────────────────
install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "→ Oh My Zsh already installed"
    return
  fi

  echo "→ Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_ohmyzsh

# ── Install shell tools ──────────────────────────────────────────
install_deps() {
  echo "→ Installing shell tools (fzf, zoxide, bat, eza)..."
  case "$PM" in
    brew)   brew install fzf zoxide bat eza zsh-autosuggestions 2>/dev/null || true ;;
    apt)    sudo apt-get install -y fzf zoxide bat eza 2>/dev/null || true ;;
    pacman) sudo pacman -S --noconfirm --needed fzf zoxide bat eza zsh-autosuggestions 2>/dev/null || true ;;
    dnf)    sudo dnf install -y fzf zoxide bat eza 2>/dev/null || true ;;
    zypper) sudo zypper install -y fzf zoxide bat eza 2>/dev/null || true ;;
  esac
}

install_deps

# ── Install zsh-autosuggestions (git clone fallback) ──────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ZAS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"

if [[ "$PM" != "brew" && "$PM" != "pacman" ]]; then
  if [[ ! -d "$ZAS_DIR" ]]; then
    echo "→ Installing zsh-autosuggestions via git..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZAS_DIR" 2>/dev/null || true
  else
    echo "→ zsh-autosuggestions already installed"
  fi
fi

# ── Create symlink ────────────────────────────────────────────────
TARGET="$HOME/.zshrc"

if [[ -f "$TARGET" && ! -L "$TARGET" ]]; then
  BACKUP="${TARGET}.backup.$(date +%Y%m%d%H%M%S)"
  echo "→ Backing up existing $TARGET to $BACKUP"
  mv "$TARGET" "$BACKUP"
elif [[ -L "$TARGET" ]]; then
  rm "$TARGET"
fi

ln -s "${SCRIPT_DIR}/.zshrc" "$TARGET"
echo "✔ Linked .zshrc → $TARGET"

# ── Set zsh as default shell ──────────────────────────────────────
if [[ "$SHELL" != *"zsh"* ]]; then
  ZSH_PATH="$(command -v zsh)"
  if [[ -n "$ZSH_PATH" ]]; then
    echo "→ Setting zsh as default shell..."
    if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH" 2>/dev/null || echo "→ Run manually: chsh -s $ZSH_PATH"
  fi
fi
