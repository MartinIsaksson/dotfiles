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

# --- AIChat: integration + completions + keybinds (Alt-E / Esc Esc) ---
if command -v aichat >/dev/null 2>&1; then
  # 1) Integration: prefer upstream script, else fallback widget
  if [[ -f "$HOME/.config/aichat/integration.zsh" ]]; then
    source "$HOME/.config/aichat/integration.zsh"
  else
    _aichat_zsh() {
      if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"; zle -I && zle redisplay
        BUFFER="$(aichat -e "$_old")"
        zle end-of-line
      fi
    }
    zle -N _aichat_zsh
  fi

  # 2) Completions (if installer dropped them)
  if [[ -d "$HOME/.config/aichat/completions" ]]; then
    fpath=("$HOME/.config/aichat/completions" $fpath)
    # ensure compinit is available/initialized
    autoload -Uz compinit 2>/dev/null || true
    if ! command -v compinit >/dev/null 2>&1; then autoload -Uz compinit; fi
    # run compinit only if not already done (skip noise)
    [[ -n "${_comps_loaded:-}" ]] || { compinit -u 2>/dev/null && _comps_loaded=1; }
    # some installs ship a concrete file too
    [[ -f "$HOME/.config/aichat/completions/aichat.zsh" ]] && source "$HOME/.config/aichat/completions/aichat.zsh"
  fi

  # 3) Key bindings: Alt-E (Esc+e) and Esc Esc
  bindkey '^[e' _aichat_zsh      # Alt-E (Option+E) in most terminals
  bindkey '\ee' _aichat_zsh      # Esc then 'e' (same as above in zle notation)
  bindkey '\e\e' _aichat_zsh     # Esc Esc (for muscle memory)
  
  # macOS-specific: ensure Option key works as Alt (complementing terminal config)
  if [[ "$OSTYPE" == darwin* ]]; then
    bindkey '^[e' _aichat_zsh    # Ensure Option+E works on macOS
    # Additional fallbacks for different terminal Option key interpretations
    bindkey '∂' _aichat_zsh      # Option+d (if terminal sends this)
    bindkey '´e' _aichat_zsh     # Some terminals may send this for Option+e
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