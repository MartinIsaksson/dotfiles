# ====================================
#  Zsh configuration for dev terminal
#
#  This file defines a modern Zsh environment with a consistent look and
#  behaviour across macOS, Linux and WSL.  It assumes tools like
#  oh‑my‑posh, fzf, zoxide, atuin and direnv are already installed (see
#  bootstrap.sh for installation).  Feel free to customise aliases or
#  add additional exports as needed.
# ====================================

# Homebrew / Linuxbrew environment
if command -v brew >/dev/null 2>&1; then
  eval "$($(command -v brew) shellenv)"
fi

# Prompt: use Oh‑My‑Posh with the provided theme
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config ~/.config/omp/theme.json)"
fi

# FZF defaults and key‑binding helpers
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_ALT_C_COMMAND='fd -t d . 2>/dev/null || find . -type d 2>/dev/null'
# If installed via Homebrew, additional keybindings may live in ~/.fzf.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide: smarter `cd`
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Atuin: local history search (no cloud sync by default)
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

# direnv: per‑directory environment management
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ------------------------------------------------------------------------------
#  AIChat integration and completions
#
#  If the `aichat` CLI is installed this block adds two enhancements:
#  1. An "intelligent completion" key binding on Alt+E (⌥‑E).  When pressed
#     your current command is sent to `aichat -e` and replaced with the
#     generated suggestion.  The function and key binding come from the
#     upstream aichat shell integration script【795010549030277†L278-L287】.
#  2. Tab completion for `aichat` itself.  The completion script is downloaded
#     into `~/.config/aichat/completions/aichat.zsh` by the installation
#     scripts.  It registers `_aichat` as the completion function and adds
#     helpful suggestions when you type `aichat <TAB>`【795010549030277†L296-L299】.
if command -v aichat >/dev/null 2>&1; then
  # Source the key binding integration if present
  if [[ -f "$HOME/.config/aichat/integration.zsh" ]]; then
    source "$HOME/.config/aichat/integration.zsh"
  fi
  # Load completions.  We add the completions directory to fpath so zsh can
  # find functions automatically.  Then we source the file to register the
  # completion definitions.  Without this the `_aichat` function will not be
  # defined.
  if [[ -f "$HOME/.config/aichat/completions/aichat.zsh" ]]; then
    fpath=("$HOME/.config/aichat/completions" $fpath)
    # shellcheck disable=SC1090
    source "$HOME/.config/aichat/completions/aichat.zsh"
  fi
fi

# NVM (Node Version Manager) initialisation
export NVM_DIR="$HOME/.nvm"
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  . "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
  . "/usr/local/opt/nvm/nvm.sh"
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
elif [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

# Debian: alias bat to batcat when needed
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  alias bat=batcat
fi

# PATH: prepend user local bin so that locally installed binaries are preferred
export PATH="$HOME/.local/bin:$PATH"

# Aliases / helpers
alias ll='eza -l --git --icons 2>/dev/null || ls -l'
alias la='eza -la --git --icons 2>/dev/null || ls -la'
alias cat='bat --style=plain --paging=never 2>/dev/null || cat'
alias gs='git status -sb'
alias gc='git commit -v'
alias gp='git pull --ff-only && git push'
alias rgg='rg -n --hidden --follow --glob "!.git/*"'

# tmux auto‑attach (disabled by default).  Uncomment to attach to a session
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
  :
  # tmux attach -t dev || tmux new -s dev
fi