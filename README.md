# Cross‑Platform Dotfiles

These dotfiles provide a unified terminal experience across macOS, Linux and WSL. They install a small set of modern command‑line utilities, configure a colourful prompt via Oh My Posh and set sensible defaults in your zsh shell. The goal is to make each machine feel the same so that you can switch contexts without friction.

## Background

Maintaining consistent shell behaviour on multiple operating systems can be tricky. Bas Nijholt notes that truly cross‑platform setups should work reliably on both macOS and many Linux distributions. Calvin Bui achieves this by inspecting the output of `uname -s` to select per‑OS configuration. These dotfiles follow the same philosophy: detect the platform, install the right packages and use the same zsh configuration everywhere. When running inside WSL, follow the Linux installation guidance as the Oh My Posh documentation recommends.

## What's Included

- **Modern CLI tools** – installs `eza` (a colourful replacement for `ls`), `bat` (syntax‑highlighted cat), `fzf` (fuzzy finder), `ripgrep` (`rg`), `tmux`, `direnv`, `tldr` and a shim for `batcat` on Debian based systems. It also installs `zoxide` and `atuin` via their official scripts when not available in your package manager.

- **Oh My Posh prompt** – a theme file (`theme.json`) defines a left‑hand segment with your user/host, working directory and git branch, and a right‑hand segment with the current time and the exit status of the last command. Oh My Posh is installed automatically; on Linux this uses the official script and on macOS it uses Homebrew. If you want to customise the prompt further, edit `theme.json`.

- **Unified `.zshrc`** – sets up Homebrew's environment when present, initialises the prompt, defines default options for `fzf`, initialises `zoxide`, `atuin`, `direnv` and `nvm`, provides a Debian `bat` alias and defines handy aliases (`ll`, `la`, `cat`, `gs`, `gc`, `gp`, `rgg`). The file is idempotent; you can copy it across machines without modification. AIChat integration and completions are sourced automatically when `aichat` is installed.

- **AIChat integration** – the `init.sh` script installs AIChat using your package manager and fetches the upstream shell integration and completion scripts. When AIChat is present your terminal gains an **Alt+E** key binding that sends the current command to AIChat and replaces it with its suggestion, plus tab‑completion for the `aichat` command.

- **Ollama installation** – optionally installs Ollama via Homebrew or the official install script. During setup you can choose to download a local LLM model (default `qwen3:8b`) using `ollama pull`.

## Prerequisites

Before running the bootstrap script ensure you have:

1. **A Unix‑like environment** – macOS, Linux or WSL. Native Windows users should open a WSL shell and follow the Linux installation route.

2. **Administrator privileges or sudo** so that your package manager can install software.

3. **A Nerd Font** installed and configured in your terminal. Oh My Posh documentation recommends a Nerd Font for proper icon rendering.

4. **Git** installed. If Git is missing you can install it via Homebrew (`brew install git`), apt (`sudo apt-get install -y git`), dnf (`sudo dnf install -y git`), pacman (`sudo pacman -S --noconfirm git`) or zypper (`sudo zypper install -y git`).

## Installation

### 1. Clone the repository

Pick a location under your home directory, e.g. `~/dotfiles`, and clone this repository there. You can use plain Git or the GitHub CLI:

```bash path=null start=null
# using git
git clone https://github.com/your‑username/dotfiles.git ~/dotfiles
cd ~/dotfiles

# or using the GitHub CLI
gh repo clone your‑username/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 2. Run the initialisation script

Use the provided `init.sh` to perform all setup steps in one go. This script will:

- Detect your operating system (macOS, Linux, WSL) and call `bootstrap.sh` to install core tools and copy the dotfiles.

- Install AIChat via your package manager (`brew install aichat` on macOS, `pacman -S aichat` on Arch, or `cargo install aichat` if cargo is available). If installation isn't possible the script will warn and continue.

- Download the shell integration and completion scripts for AIChat from the upstream repository and save them under `~/.config/aichat`. These scripts enable intelligent completions on **Alt+E** and tab‑completion for the `aichat` command.

- Install Ollama (`brew` on macOS, or the official install script on Linux) and optionally download a model via `ollama pull`. You'll be prompted to accept the default model `qwen3:8b` or specify another one.

Run `init.sh` from the root of the repository:

```bash path=null start=null
bash init.sh
```

The script will prompt before overwriting an existing `~/.zshrc` (via `bootstrap.sh`) and before downloading an Ollama model. If you choose to overwrite, the current file will be backed up with a timestamp.

### 3. Restart your shell

After the initialisation completes, restart your terminal or run `exec zsh` to reload the configuration. You should see a coloured prompt showing your username, hostname and current directory on the left and the current time on the right. Press **Alt+E** in the terminal to invoke AIChat's shell assistant on the current command. The icons will render correctly if your terminal uses a Nerd Font.

## Windows users

On native Windows PowerShell you cannot run these scripts directly. Instead install the Windows Terminal and enable WSL, then launch a Linux distribution through WSL and follow the standard Linux installation above. The Oh My Posh project explicitly states that when using the prompt inside WSL you should follow the Linux installation instructions.

## Acceptance Criteria

Use this checklist to verify that the environment is set up correctly on a new machine:

1. **Tools installed** – run each command and ensure it executes without "command not found": `zsh`, `eza`, `bat` (or `batcat`), `fzf`, `rg`, `tmux`, `direnv`, `tldr`, `zoxide`, `atuin`, `oh-my-posh`.

2. **Prompt renders** – open a new terminal and ensure the prompt shows `user@host ~/path` on the left and the current time on the right. Commit status should appear when in a git repository. Nerd Font icons should display correctly.

3. **Aliases available** – run `ll` and `la` and confirm you get a coloured, git‑aware directory listing; `cat` should syntax highlight files via `bat`; `gs`, `gc` and `gp` should wrap git; `rgg` should search recursively with ripgrep.

4. **fzf integration** – press **Ctrl‑T** and **Alt‑C** in the shell and ensure the fuzzy finder shows files and directories respectively. If installed via Homebrew the installer adds additional keybindings.

5. **Navigation and history** – after visiting a few directories use `cd -` to jump back and forth. Ensure `zoxide` remembers visited directories and fuzzy navigation works. Use **Ctrl‑R** to search your history via Atuin.

6. **direnv** – create a `.envrc` file in a directory with `export TEST=123` and run `direnv allow`; opening a new shell in that directory should set `TEST` automatically. Leaving the directory should unset it.

7. **NVM** – run `nvm --version`. If NVM isn't installed the section in `.zshrc` will silently do nothing; you can install NVM later and it will be picked up automatically.

8. **AIChat installed** – run `aichat --version`. The command should succeed. Press **Alt+E** in the shell with some text typed; the line should be replaced by AIChat's suggestion and executed. Type `aichat <Tab>` and verify that zsh offers completions for flags and subcommands.

9. **Ollama installed** – run `ollama --version` and ensure the command exists. If you chose to download a model during setup, run `ollama list` and confirm that the model (default `qwen3:8b`) appears in the output.

If any of these steps fail, double‑check your package manager installation and review the console output from the bootstrap script for errors. Some distributions may not provide certain packages – the script warns when `eza` or `bat` cannot be installed and links to their release pages.

## Customisation

- **Changing the prompt** – edit `theme.json` and restart your shell. The schema is documented on the Oh My Posh website.

- **Adding packages** – edit `bootstrap.sh`, append the package name to the `PKG_LIST` array and re‑run the script. When adding OS specific packages you can use the `distribution` variable to choose the correct name.

- **Shell extensions** – the `.zshrc` is intentionally minimal. Feel free to add plugins using a plugin manager like antidote or Oh My Zsh in the standard way.

## References

- Bas Nijholt's cross‑platform dotfiles emphasise reliability across macOS and multiple Linux architectures.

- Calvin Bui describes using `uname` to differentiate operating systems and select configuration accordingly.

- The official Oh My Posh documentation recommends installing a Nerd Font and following the Linux installation guide when running inside WSL.

- Oh My Posh can be installed on Linux by piping the provided install script to bash; on macOS it's available via Homebrew.

## Key Additions

- **AIChat shell integration and completion**: `init.sh` installs the AIChat CLI (`brew` on macOS, `pacman` on Arch, or `cargo` on other Linux distros), downloads the upstream integration/completion scripts, and `.zshrc` sources them automatically.

- **Ollama installation and model prompt**: `init.sh` installs Ollama via Homebrew or the official Linux install script and prompts the user to pull a model (default `qwen3:8b`).

- Robust OS detection and improved error handling in the scripts (e.g., apt‑get failures no longer abort the process).

- README.md expanded to include instructions for running `init.sh`, details about AIChat and Ollama features, and updated acceptance criteria covering AIChat usage and model installation.

Run `bash init.sh` from the root of the repository after cloning. The script will walk you through the setup, prompt before overwriting an existing `.zshrc`, install AIChat and Ollama, and optionally download an Ollama model. After completion, restart your terminal or run `exec zsh` to activate the environment and try pressing **Alt+E** for AIChat-assisted shell completions.
