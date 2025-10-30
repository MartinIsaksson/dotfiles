#!/usr/bin/env bash
#
# init.sh — one‑time setup wrapper for the dotfiles repository.
#
# This script orchestrates the entire environment bootstrap.  It calls
# `bootstrap.sh` to install core CLI tools and copy dotfiles, then installs
# AIChat with shell integration and completions, installs Ollama and
# optionally downloads a local model.  It is designed to run on macOS,
# Linux or WSL; native Windows users should run it from within WSL.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Step 1: Run the base bootstrap
#
# This installs zsh, fzf, ripgrep, tmux, direnv, tldr, zoxide, atuin and
# oh‑my‑posh, then copies the `.zshrc` and theme file into the appropriate
# locations.  It will prompt before overwriting an existing `~/.zshrc`.
###############################################################################
echo "[*] Running bootstrap…"
bash "$script_dir/bootstrap.sh"

###############################################################################
# Step 2: Detect OS and choose a package manager
#
# We inspect uname and available package managers to decide how to install
# additional software.  This mirrors the detection logic in bootstrap.sh.
###############################################################################
OS="$(uname -s)"
DISTRO=""
PM=""

if [[ "$OS" == "Darwin" ]]; then
  PM="brew"
elif [[ "$OS" == "Linux" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    DISTRO="debian"
    PM="apt-get"
  elif command -v dnf >/dev/null 2>&1; then
    DISTRO="fedora"
    PM="dnf"
  elif command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
    PM="pacman"
  elif command -v zypper >/dev/null 2>&1; then
    DISTRO="suse"
    PM="zypper"
  fi
fi

###############################################################################
# Helper: run a command with sudo if available
###############################################################################
run_cmd() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

###############################################################################
# Step 3: Install AIChat
#
# AIChat provides an all‑in‑one AI CLI with a shell assistant.  We install it
# using the best available method per platform.  For macOS we use Homebrew; on
# Arch we use pacman; on other Linux distributions we fall back to cargo if
# available.  If installation fails we warn the user.
###############################################################################
if ! command -v aichat >/dev/null 2>&1; then
  echo "[*] Installing AIChat…"
  case "$PM" in
    brew)
      brew install aichat || true
      ;;
    pacman)
      run_cmd pacman -Sy --noconfirm aichat || true
      ;;
    apt-get|dnf|zypper)
      if command -v cargo >/dev/null 2>&1; then
        cargo install aichat || true
      else
        echo "[!] Could not find a package for AIChat on this distribution and cargo is unavailable." >&2
        echo "    Please install AIChat manually (see https://github.com/sigoden/aichat#install)." >&2
      fi
      ;;
    *)
      echo "[!] Unknown package manager; skipping AIChat installation." >&2
      ;;
  esac
else
  echo "[ok] AIChat already installed"
fi

###############################################################################
# Step 4: Download shell integration and completion scripts
#
# Once AIChat is installed we fetch the upstream scripts to enable the Alt+E
# assistant and tab completion.  They are placed under ~/.config/aichat and
# sourced from .zshrc.  The downloads will be attempted regardless of whether
# AIChat installation succeeded so users can reuse existing binaries.
###############################################################################

ai_config_dir="$HOME/.config/aichat"
mkdir -p "$ai_config_dir/completions"

integration_url="https://raw.githubusercontent.com/sigoden/aichat/main/scripts/shell-integration/integration.zsh"
completion_url="https://raw.githubusercontent.com/sigoden/aichat/main/scripts/completions/aichat.zsh"

echo "[*] Fetching AIChat shell integration…"
if curl -fsSL "$integration_url" -o "$ai_config_dir/integration.zsh"; then
  echo "[ok] Installed AIChat shell integration script to $ai_config_dir/integration.zsh"
else
  echo "[!] Failed to download AIChat integration script from $integration_url" >&2
fi

echo "[*] Fetching AIChat completion script…"
if curl -fsSL "$completion_url" -o "$ai_config_dir/completions/aichat.zsh"; then
  echo "[ok] Installed AIChat completion script to $ai_config_dir/completions/aichat.zsh"
else
  echo "[!] Failed to download AIChat completion script from $completion_url" >&2
fi

###############################################################################
# Step 5: Install Ollama
#
# Ollama is a local LLM runtime.  On macOS we install via Homebrew.  On Linux
# we use the official installer.  If installation fails we warn the user.
###############################################################################

if ! command -v ollama >/dev/null 2>&1; then
  echo "[*] Installing Ollama…"
  case "$PM" in
    brew)
      brew install ollama || true
      ;;
    *)
      # Use official install script for Linux/WSL
      if curl -fsSL https://ollama.com/install.sh | run_cmd sh; then
        echo "[ok] Ollama installed via official script"
      else
        echo "[!] Failed to install Ollama; please install manually from https://ollama.com" >&2
      fi
      ;;
  esac
else
  echo "[ok] Ollama already installed"
fi

###############################################################################
# Step 6: Optional model download
#
# Prompt the user to download a model using `ollama pull`.  The default
# suggestion is qwen3:8b.  Skip this step if ollama is unavailable.
###############################################################################
if command -v ollama >/dev/null 2>&1; then
  # Ask if user wants to download a model
  echo
  read -r -p "Would you like to download an Ollama model now? [Y/n] " download_model
  download_model="${download_model:-Y}"
  case "$download_model" in
    [nN]*)
      echo "[i] Skipping model download.  You can pull models later with 'ollama pull <model>'."
      ;;
    *)
      model_name="qwen3:8b"
      read -r -p "Enter the model name to pull (default: qwen3:8b): " input_model || input_model=""
      if [[ -n "$input_model" ]]; then
        model_name="$input_model"
      fi
      echo "[*] Pulling model $model_name..."
      if ollama pull "$model_name"; then
        echo "[ok] Model $model_name downloaded"
      else
        echo "[!] Failed to download model $model_name" >&2
      fi
      ;;
  esac
fi

###############################################################################
# Completion
###############################################################################
echo
echo "[✔] Initialisation complete. Restart your terminal or run 'exec zsh' to reload."