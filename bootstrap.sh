#!/usr/bin/env bash
# This bootstrap script prepares a consistent terminal environment across
# macOS, Linux and WSL.  It installs a handful of modern CLI tools,
# copies your preferred dotfiles into place and configures a custom
# Oh‑My‑Posh prompt.  It is designed to run once on a fresh machine.
set -euo pipefail

###############################################################################
#  Detect platform and choose a package manager                                        
#                                                                                     
#  On macOS we rely on Homebrew.  On Linux we inspect the available package          
#  managers in order of precedence.  The order matches common distributions
#  (Debian/Ubuntu → Fedora/RHEL → Arch → openSUSE).  Windows users should run
#  this script inside WSL; native PowerShell users can use the provided
#  bootstrap.ps1 instead.
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
  else
    echo "[ERROR] Unsupported Linux distribution. Please install dependencies manually." >&2
    exit 1
  fi
else
  echo "[ERROR] Unsupported platform '$OS'. Use bootstrap.ps1 on Windows or run under WSL." >&2
  exit 1
fi

###############################################################################
#  Helper: install a single package                                                
#                                                                                  
#  Uses the selected package manager to install a package if it isn't already
#  available in $PATH.  Each case handles the appropriate syntax per manager.  If
#  sudo is missing the command is executed directly.  On systems without root
#  privileges the install will fail gracefully and the user will be notified.
###############################################################################
install_pkg() {
  local pkg="$1"
  # bail early if the tool is already present
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "[ok] $pkg already installed"
    return 0
  fi

  # define a wrapper for running privileged commands.  Use sudo when available
  # otherwise run the underlying command directly.  The user is expected to
  # provide necessary privileges or install the software manually.
  run_cmd() {
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      "$@"
    fi
  }

  case "$PM" in
    brew)
      # with homebrew the formula name equals the binary name in most cases
      if brew list --formula "$pkg" >/dev/null 2>&1; then
        echo "[ok] $pkg already installed (brew)"
      else
        brew install "$pkg"
      fi
      ;;
    apt-get)
      # refresh package cache once per run; apt-get needs root
      # update the package cache; ignore failures on systems without root
      run_cmd apt-get update -y || true
      # install the package; ignore failures so the script can continue
      run_cmd apt-get install -y "$pkg" || true
      ;;
    dnf)
      run_cmd dnf install -y "$pkg" || true
      ;;
    pacman)
      run_cmd pacman -Sy --noconfirm "$pkg" || true
      ;;
    zypper)
      run_cmd zypper install -y "$pkg" || true
      ;;
    *)
      echo "[ERROR] Unknown package manager $PM" >&2
      return 1
      ;;
  esac
}

###############################################################################
#  Ensure Homebrew is present on macOS                                            
#                                                                                 
#  Homebrew is used to install many of the CLI tools.  If brew isn't available
#  we install it from the official script.  The `eval` call adds brew to the
#  current PATH immediately.
###############################################################################
if [[ "$PM" == "brew" ]] && ! command -v brew >/dev/null 2>&1; then
  echo "[*] Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" || true
fi

###############################################################################
#  Install core packages                                                          
#                                                                                 
#  We group packages into a list for readability.  Feel free to add additional
#  tools here (e.g. python, git extras) as your workflow evolves.  Debian
#  packages sometimes differ by name; adjust as necessary.  Missing packages
#  will be skipped gracefully.
###############################################################################
echo "[*] Installing core packages…"
PKG_LIST=(
  zsh
  fzf
  ripgrep
  tmux
  direnv
  tldr
)

# distribution-specific names
PKG_EZA="eza"
PKG_BAT="bat"
if [[ "$DISTRO" == "debian" ]]; then
  # Debian/Ubuntu uses the package name 'bat' but the binary is batcat
  PKG_BAT="bat"
fi
PKG_LIST+=("$PKG_EZA" "$PKG_BAT")

for pkg in "${PKG_LIST[@]}"; do
  install_pkg "$pkg"
done

###############################################################################
#  Fallback handling for tools not present in distro repos                          
#                                                                                    
#  Some distributions don't ship certain modern tools.  Warn the user when a
#  package fails to install so they can manually download a prebuilt binary or
#  choose an alternative installation method (e.g. GitHub releases).
###############################################################################
if ! command -v eza >/dev/null 2>&1; then
  echo "[!] 'eza' could not be installed via $PM. Consider downloading from https://github.com/eza-community/eza/releases"
fi
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
  echo "[!] 'bat' could not be installed via $PM. Consider downloading from https://github.com/sharkdp/bat/releases"
fi

# Provide a shim on Debian where batcat is the installed binary name
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  export PATH="$HOME/.local/bin:$PATH"
fi

###############################################################################
#  Install zoxide                                                                  
#                                                                                  
#  zoxide is a smarter cd replacement.  Many package managers don't ship it yet
#  so we install it via the official script when missing.  Binary is placed
#  under ~/.local/bin which is prepended to PATH.
###############################################################################
if ! command -v zoxide >/dev/null 2>&1; then
  echo "[*] Installing zoxide…"
  case "$PM" in
    brew)
      brew install zoxide || true
      ;;
    *)
      # install via upstream installer (no root required)
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- -b "$HOME/.local/bin" || true
      ;;
  esac
fi

###############################################################################
#  Install Atuin                                                                  
#                                                                                  
#  Atuin provides a modern, searchable shell history.  We install it from
#  upstream if it isn't present.
###############################################################################
if ! command -v atuin >/dev/null 2>&1; then
  echo "[*] Installing Atuin…"
  case "$PM" in
    brew)
      brew install atuin || true
      ;;
    *)
      curl -sS https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh | bash || true
      ;;
  esac
fi

###############################################################################
#  Install Oh‑My‑Posh                                                             
#                                                                                  
#  Oh‑My‑Posh powers the colourful prompt.  It can be installed via Homebrew
#  on macOS or via the official script on Linux/WSL.  The binary is placed
#  under ~/.local/bin.
###############################################################################
if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "[*] Installing oh-my-posh…"
  case "$PM" in
    brew)
      brew install jandedobbeleer/oh-my-posh/oh-my-posh || true
      ;;
    *)
      curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" || true
      ;;
  esac
fi

###############################################################################
#  Copy configuration files                                                      
#                                                                                 
#  After the tooling is in place we copy your dotfiles from the repo.  We ask
#  before clobbering an existing .zshrc.  theme.json is always overwritten to
#  ensure updates are picked up.
###############################################################################
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ensure configuration directories exist
mkdir -p "$HOME/.config/omp"

# copy prompt theme
cp -f "$script_dir/theme.json" "$HOME/.config/omp/theme.json"
echo "[ok] Installed theme to ~/.config/omp/theme.json"

# copy .zshrc with confirmation if it already exists
target_zshrc="$HOME/.zshrc"
source_zshrc="$script_dir/.zshrc"
if [[ -f "$target_zshrc" ]]; then
  read -p "An existing ~/.zshrc was found. Overwrite it with the repository version? [y/N] " answer
  case "$answer" in
    [yY]* )
      mv "$target_zshrc" "$target_zshrc.backup.$(date +%s)"
      cp "$source_zshrc" "$target_zshrc"
      echo "[ok] Replaced ~/.zshrc (backup saved)"
      ;;
    * )
      echo "[!] Skipping ~/.zshrc update. Please merge changes manually."
      ;;
  esac
else
  cp "$source_zshrc" "$target_zshrc"
  echo "[ok] Installed ~/.zshrc"
fi

###############################################################################
#  Final notes                                                                    
#                                                                                  
#  A final reminder to restart the shell so the new configuration is sourced.
###############################################################################
echo
echo "[✔] Bootstrap complete. Restart your terminal or run 'exec zsh' to reload."
echo "    A Nerd Font is recommended for proper icon rendering (e.g. https://www.nerdfonts.com)."