# Dotfiles

Intelligent, cross-platform bash dotfiles for macOS and Linux with smart dependency management.

**⚠️ Bash-only** - These dotfiles require bash as your default shell.

## Features

✅ **Bash-Only** - Simple, focused, no multi-shell complexity
✅ **Smart Alias System** - Only sets aliases for installed tools
✅ **Auto Dependency Detection** - Checks for missing tools and offers to install them
✅ **Safe Command Shadowing** - Replaces ls/cat/grep with better modern alternatives
✅ **Idempotent Setup** - Run multiple times safely
✅ **Minimal Footprint** - Single shim in `~`, everything else in repo
✅ **Cross-Platform** - Works on macOS (Homebrew) and Linux (apt)
✅ **Bash 3.2 Compatible** - Works with macOS default bash

## Quick Start

### New Machine

```bash
# Clone the repo
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# Run full setup
bash bootstrap/setup-new-machine.sh

# Switch to bash (if not already)
chsh -s /bin/bash

# Close terminal and open a new one - done!
```

This will:
1. Check and install missing dependencies (fd, bat, eza, rg, gh, jq)
2. Create tool symlinks in `~/bin`
3. Configure git to use dotfiles settings
4. Create `~/.bash_profile` that sources from dotfiles
5. Create `~/.zshrc` with message to switch to bash

### Sync Existing Machine

```bash
cd ~/dotfiles
git pull
bash bootstrap/sync.sh  # Validates everything and installs missing tools
src                      # Reload shell
```

The `sync.sh` script:
- ✓ Checks for missing dependencies and offers to install them
- ✓ Validates all symlinks are correct
- ✓ Verifies shell configuration
- ✓ Confirms git config is set up
- ✓ Reports any issues found

## How It Works

### Architecture

```
~/.bash_profile          # Tiny shim → sources ~/dotfiles/shell/bashrc
~/.zshrc                 # Message: "Please switch to bash"
~/bin/                   # Symlinks to ~/dotfiles/tools/*
~/dotfiles/              # This repo ← everything lives here
  ├── bootstrap/         # Setup scripts
  ├── shell/             # All bash configuration
  │   ├── bashrc                # Main loader (sources all [0-9]* files)
  │   ├── 00_env                # PATH, exports
  │   ├── 01_alias_system.sh    # Smart alias engine
  │   ├── 10_os_darwin          # macOS-specific
  │   ├── 10_os_linux           # Linux-specific
  │   ├── 20_aliases_common     # Main aliases
  │   ├── 30_docker_aliases     # Docker helpers
  │   ├── 40_functions          # Shell functions
  │   └── 99_interactive        # Interactive shell settings (history, prompt)
  ├── tools/             # Custom scripts (symlinked to ~/bin)
  └── git/               # Git config and hooks
```

**Key Design**: Single `shell/` directory with numbered files loaded in order. Bash-only - no shell compatibility complexity.

### Smart Alias System

The intelligent alias system (`01_alias_system.sh`) validates before setting aliases:

1. **Checks if tools exist** - Won't create alias for missing command
2. **Detects conflicts** - Warns if shadowing existing commands
3. **Allows approved shadows** - ls→eza, cat→bat, grep→rg are approved
4. **Reports missing tools** - Shows what's missing on shell startup
5. **Graceful fallback** - Uses sensible defaults if tools unavailable

Example:
```bash
# Only sets alias if eza is installed
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
else
  # Fallback to regular ls
  alias ll='ls -lh'
fi
```

### Approved Command Replacements

Modern replacements for common tools (auto-enabled if installed):

- **ls** → **eza** - Better ls with git integration, colors
- **cat** → **bat** - Syntax highlighting, line numbers
- **grep** → **rg** (ripgrep) - Much faster, better UX
- **find** → **fd** - Simpler syntax, respects .gitignore

## Bootstrap Scripts

| Script | Purpose |
|--------|---------|
| `setup-new-machine.sh` | **Full setup**: install tools, create shims, configure git, validate |
| `sync.sh` | **Daily use**: validate system state, install missing tools, update symlinks |
| `check_dependencies.sh` | Check for missing tools, offer to install via brew/apt |
| `dry-run.sh` | Preview what setup would change (no modifications) |
| `cleanup.sh` | Remove old conflicting shell configs |
| `link_tools.sh` | Create symlinks from ~/bin to tools/ |
| `setup_shell.sh` | Create shell shim in ~ |
| `configure_git.sh` | Setup git to include dotfiles config |

## Required Tools

These tools are checked and auto-installed by `check_dependencies.sh`:

- **fd** - Fast file finder (`brew install fd` / `apt install fd-find`)
- **bat** - Better cat (`brew install bat` / `apt install bat`)
- **eza** - Modern ls (`brew install eza` / `apt install eza`)
- **ripgrep** - Fast grep (`brew install ripgrep` / `apt install ripgrep`)
- **gh** - GitHub CLI (`brew install gh` / `apt install gh`)
- **jq** - JSON processor (`brew install jq` / `apt install jq`)

On first shell load, if tools are missing you'll see:

```
⚠️  Missing tools for some aliases: bat fd
   Run: ~/dotfiles/bootstrap/check_dependencies.sh
```

## Customization

### Adding Aliases

Edit `shell/20_aliases_common`:

```bash
# Safe alias - only sets if tool exists
safe_alias myalias 'mytool --flag' mytool

# Conditional - same as safe_alias
conditional_alias short 'long-command' long-command

# Always set (for navigation, etc)
alias myshortcut='cd ~/path'
```

### Adding Custom Tools

1. Add script to `tools/my_script.sh`
2. Edit `bootstrap/link_tools.sh`:
   ```bash
   LINKS=(
     "mytool:my_script.sh"
   )
   ```
3. Run: `bash bootstrap/link_tools.sh`

### Platform-Specific Config

Use the `$DOTFILES_OS` variable:

```bash
if [[ "$DOTFILES_OS" == "Darwin" ]]; then
  # macOS specific
elif [[ "$DOTFILES_OS" == "Linux" ]]; then
  # Linux specific
fi
```

## Debugging

### Shell not loading?

```bash
echo $SHELL                 # Check current shell (should be /bin/bash)
source ~/.bash_profile      # Reload bash
```

### Missing aliases?

```bash
alias                       # List all aliases
type myalias               # Check specific alias
which mytool               # Check if tool exists
```

### Check what would be installed

```bash
bash bootstrap/dry-run.sh  # Preview changes
```

### macOS: "zsh is now default" message?

This is normal - it's just macOS being annoying. You're still using bash. The setup scripts silence this warning automatically.

## Philosophy

**Bash-Only**
No complexity from supporting multiple shells. Simple, focused, maintainable.

**Minimal System Changes**
Only a small shim file in `~/.bash_profile`. Everything else sourced/symlinked from repo.

**Intelligent Defaults**
Aliases only load if tools exist. Graceful fallbacks for missing tools.

**Cross-Platform**
Same config works on macOS and Linux with platform detection.

**Developer Friendly**
Edit in `~/dotfiles`, changes apply immediately with `src` command.

**Idempotent**
Safe to run setup multiple times.

## Directory Layout

```
dotfiles/
├── .gitignore
├── README.md
├── bootstrap/
│   ├── check_dependencies.sh    # Check & install missing tools
│   ├── cleanup.sh               # Remove old configs
│   ├── configure_git.sh         # Setup git
│   ├── dry-run.sh               # Preview changes
│   ├── link_tools.sh            # Symlink tools
│   ├── packages.apt             # Linux packages
│   ├── packages.brew            # macOS packages
│   ├── setup-new-machine.sh     # Full setup
│   └── setup_shell.sh           # Create shell shim
├── git/
│   ├── bin/
│   ├── config/
│   └── hooks/
├── shell/                        # All bash configuration
│   ├── bashrc                   # Main loader
│   ├── 00_env                   # PATH, env vars
│   ├── 01_alias_system.sh       # Smart alias engine
│   ├── 10_os_darwin             # macOS-specific
│   ├── 10_os_linux              # Linux-specific
│   ├── 15_gh_proto_aliases      # GitHub shortcuts
│   ├── 20_aliases_common        # Main aliases
│   ├── 30_docker_aliases        # Docker helpers
│   ├── 40_functions             # Shell functions
│   ├── 45_function_helpers      # Helper functions
│   ├── 50_zeek.sh               # Zeek-specific
│   └── 99_interactive           # Interactive bash settings
└── tools/
    ├── check-env.sh
    ├── countlines.sh
    ├── remove_trailing_whitespace.sh
    └── zeek_runner.sh
```

## License

MIT
