# Machine Bootstrap

Bootstrap script for setting up a new macOS or Linux development machine.

## Usage

```bash
./bootstrap.sh
```

### Headless Mode

For remote dev environments (Linux VMs, containers, cloud instances):

```bash
./bootstrap.sh --headless
```

This skips GUI applications, macOS-specific settings, and interactive prompts.

## What It Installs

### Prerequisites (auto-installed)

- Xcode Command Line Tools (macOS)
- Build essentials (Linux)
- Homebrew

### GUI Applications (Homebrew Casks)

Ghostty, Google Chrome, Cursor, Notion, Slack, OrbStack, CleanShot, Screen Studio, Raycast, Rectangle, Karabiner Elements

### GUI Applications (Direct Installers)

Linear, Discord

### CLI Tools (Homebrew Formulas)

gh, fzf, zoxide, fnm, eza, tree, htop, jq, go, mkcert, spaceship, ripgrep, fd, bat

### Shell Setup

- Oh My Zsh with zsh-autosuggestions & zsh-syntax-highlighting
- Spaceship prompt (via Homebrew)
- Node LTS (via fnm)
- pnpm, bun

### Configuration

- SSH key generation (ed25519)
- GitHub CLI authentication
- Git user config
- Local CA setup (mkcert)
- macOS defaults (fast key repeat, Finder settings, dock autohide)

## Dotfiles

The `dotfiles/` directory contains:

- `.zshrc` - Shell configuration (aliases, PATH, prompt, plugins)
- `.gitconfig` - Git configuration (aliases, defaults)
- `.gitignore` - Global git ignores

These are symlinked to your home directory during bootstrap.

## Customization

### Adding/Removing Applications

Edit the arrays at the top of `bootstrap.sh`:

```bash
CASKS=(
    "ghostty"
    "google-chrome"
    # Add or remove casks here
)

FORMULAS=(
    "gh"
    "fzf"
    # Add or remove formulas here
)
```

### Adding Applications from Direct Installers

Use the helper functions in the script:

```bash
# For .pkg installers
install_app_from_pkg "AppName" "https://example.com/app.pkg"

# For .dmg installers
install_app_from_dmg "AppName" "https://example.com/app.dmg"
```

### Adding New Dotfiles

1. Add the file to the `dotfiles/` directory (must start with `.`)
2. Run `./bootstrap.sh` — it will be automatically symlinked

### Modifying Shell Configuration

Edit `dotfiles/.zshrc`. The file is organized into sections:

- **Platform Detection** — Sets OS-specific variables
- **PATH Configuration** — Add new PATH entries here
- **Oh My Zsh** — Plugins and theme config
- **Tool Initialization** — fzf, zoxide, fnm, etc.
- **Functions** — Custom shell functions
- **Aliases** — Organized by category (git, npm, pnpm, etc.)

### Adding macOS Defaults

Add `defaults write` commands to the macOS defaults section near the end of `bootstrap.sh`.

## Script Structure

```
bootstrap.sh
├── CONFIGURATION      # Casks and formulas arrays (edit these)
├── OPTIONS            # CLI argument parsing
├── HELPER FUNCTIONS   # Reusable install helpers
└── BOOTSTRAP SCRIPT   # Main installation logic
```

### Helper Functions

| Function | Purpose |
|----------|---------|
| `log_success`, `log_info`, `log_warn` | Consistent logging |
| `command_exists` | Check if a command is available |
| `is_macos`, `is_linux`, `is_arm64` | Platform detection |
| `brew_install_formula` | Idempotent formula install |
| `brew_install_cask` | Idempotent cask install |
| `install_app_from_pkg` | Install from .pkg URL |
| `install_app_from_dmg` | Install from .dmg URL |

## Re-running the Script

The script is idempotent — safe to run multiple times:

- Already-installed packages are skipped
- Already-linked dotfiles are skipped
- Existing dotfiles are backed up to `*.backup` before linking
