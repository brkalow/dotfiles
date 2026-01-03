#!/bin/bash
# =============================================================================
# Bootstrap script for new development environments
#
# Quick install (clone and run):
#   bash <(curl -fsSL https://raw.githubusercontent.com/brkalow/dotfiles/main/bootstrap.sh)
#
# For headless/remote environments:
#   bash <(curl -fsSL https://raw.githubusercontent.com/brkalow/dotfiles/main/bootstrap.sh) --headless
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION - Edit these to customize your setup
# =============================================================================

CASKS=(
    "ghostty"
    "google-chrome"
    "cursor"
    "notion"
    "slack"
    "orbstack"
    "cleanshot"
    "screen-studio"
    "raycast"
    "rectangle"
    "karabiner-elements"
    "tuple"
    "tableplus"
)

FORMULAS=(
    "gh"
    "fzf"
    "zoxide"
    "fnm"
    "eza"
    "tree"
    "htop"
    "jq"
    "go"
    "mkcert"
    "spaceship"
    "ripgrep"
    "fd"
    "bat"
    "tmux"
    "neovim"
    "direnv"
)

# =============================================================================
# OPTIONS
# =============================================================================

HEADLESS=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --headless) HEADLESS=true ;;
        -h|--help)
            echo "Usage: ./bootstrap.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --headless    Skip GUI apps and macOS-specific settings (for remote dev environments)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_success() { echo "✅ $1"; }
log_info() { echo "📦 $1"; }
log_skip() { echo "⏭️  $1"; }
log_warn() { echo "⚠️  $1"; }

command_exists() { command -v "$1" &> /dev/null; }
is_macos() { [[ "$(uname)" == "Darwin" ]]; }
is_linux() { [[ "$(uname)" == "Linux" ]]; }
is_arm64() { [[ $(uname -m) == "arm64" ]]; }

brew_install_formula() {
    local formula="$1"
    if brew list "$formula" &> /dev/null; then
        log_success "$formula already installed"
    else
        echo "Installing $formula..."
        brew install "$formula"
    fi
}

brew_install_cask() {
    local cask="$1"
    if brew list --cask "$cask" &> /dev/null; then
        log_success "$cask already installed"
    else
        echo "Installing $cask..."
        brew install --cask "$cask"
    fi
}

install_app_from_pkg() {
    local name="$1" url="$2"
    if [[ -d "/Applications/$name.app" ]]; then
        log_success "$name already installed"
        return
    fi
    echo "Installing $name..."
    local pkg="/tmp/$name.pkg"
    if ! curl -fsSL "$url" -o "$pkg"; then
        log_warn "Failed to download $name"
        return 1
    fi
    sudo installer -pkg "$pkg" -target /
    rm -f "$pkg"
}

install_app_from_dmg() {
    local name="$1" url="$2" volume_name="${3:-$name}"
    if [[ -d "/Applications/$name.app" ]]; then
        log_success "$name already installed"
        return
    fi
    echo "Installing $name..."
    local dmg="/tmp/$name.dmg"
    if ! curl -fsSL "$url" -o "$dmg"; then
        log_warn "Failed to download $name"
        return 1
    fi
    hdiutil attach "$dmg" -nobrowse -quiet
    cp -R "/Volumes/$volume_name/$name.app" /Applications/
    hdiutil detach "/Volumes/$volume_name" -quiet 2>/dev/null || true
    rm -f "$dmg"
}

# =============================================================================
# BOOTSTRAP SCRIPT
# =============================================================================

if [[ "$HEADLESS" == true ]]; then
    echo "🚀 Starting headless bootstrap..."
else
    echo "🚀 Starting machine bootstrap..."
fi

# Install Xcode Command Line Tools (macOS only)
if [[ "$HEADLESS" == false ]] && is_macos; then
    if xcode-select -p &> /dev/null; then
        log_success "Xcode Command Line Tools already installed"
    else
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "⏳ Waiting for Xcode CLT installation to complete..."
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
        log_success "Xcode Command Line Tools installed"
    fi
fi

# Install essential build tools on Linux
if is_linux; then
    log_info "Installing Linux build essentials..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y build-essential curl git zsh locales
    elif command_exists dnf; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y curl git zsh glibc-langpack-en
    elif command_exists yum; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y curl git zsh
    fi

    # Setup locale
    if [[ -z "$LANG" ]] || [[ "$LANG" == "C" ]] || [[ "$LANG" == "POSIX" ]]; then
        log_info "Setting up locale..."
        if command_exists locale-gen; then
            sudo locale-gen en_US.UTF-8 2>/dev/null || true
        fi
        sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 2>/dev/null || true
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
    fi
fi

# Install Homebrew if not installed
if ! command_exists brew; then
    log_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH
    if is_macos && is_arm64; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif is_linux; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
else
    log_success "Homebrew already installed"
fi

if [[ "$HEADLESS" == false ]]; then
    log_info "Installing applications..."
    for cask in "${CASKS[@]}"; do
        brew_install_cask "$cask"
    done
else
    log_skip "Skipping GUI applications (headless mode)"
fi

log_info "Installing CLI tools..."
for formula in "${FORMULAS[@]}"; do
    brew_install_formula "$formula"
done

# Install apps from official installers (macOS GUI only)
if [[ "$HEADLESS" == false ]] && is_macos; then
    if is_arm64; then
        LINEAR_URL="https://desktop.linear.app/mac/pkg/arm64"
    else
        LINEAR_URL="https://desktop.linear.app/mac/pkg/x64"
    fi
    install_app_from_pkg "Linear" "$LINEAR_URL"
    install_app_from_dmg "Discord" "https://discord.com/api/download?platform=osx"
fi

# Install Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed"
else
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_success "zsh-autosuggestions already installed"
else
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_success "zsh-syntax-highlighting already installed"
else
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Remove old oh-my-zsh spaceship theme (we use Homebrew version)
if [[ -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]]; then
    rm -rf "$ZSH_CUSTOM/themes/spaceship-prompt" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi

# Install pnpm
if command_exists pnpm; then
    log_success "pnpm already installed"
else
    echo "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Install bun
if command_exists bun; then
    log_success "bun already installed"
else
    echo "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# Setup local CA with mkcert
if is_macos; then
    MKCERT_CA_DIR="$HOME/Library/Application Support/mkcert"
else
    MKCERT_CA_DIR="$HOME/.local/share/mkcert"
fi
if [[ -f "$MKCERT_CA_DIR/rootCA.pem" ]]; then
    log_success "mkcert CA already setup"
else
    echo "Setting up mkcert local CA..."
    mkcert -install
fi

# Setup dotfiles
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    echo "🔗 Linking dotfiles..."
    for file in "$DOTFILES_DIR"/.*; do
        filename=$(basename "$file")
        if [[ "$filename" != "." && "$filename" != ".." ]]; then
            target="$HOME/$filename"
            # Skip if already correctly linked
            if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$file" ]]; then
                echo "  $filename already linked"
                continue
            fi
            # Backup existing file if it exists and isn't a symlink to our file
            if [[ -e "$target" ]]; then
                echo "  Backing up existing $filename to $filename.backup"
                mv "$target" "$target.backup"
            fi
            ln -sf "$file" "$target"
            echo "  Linked $filename"
        fi
    done

    # Link .config subdirectories (only if ~/.config is not already symlinked to dotfiles)
    if [[ -d "$DOTFILES_DIR/.config" ]]; then
        if [[ -L "$HOME/.config" ]] && [[ "$(readlink "$HOME/.config")" == "$DOTFILES_DIR/.config" ]]; then
            echo "  .config already linked as a whole"
        else
            mkdir -p "$HOME/.config"
            for config_dir in "$DOTFILES_DIR/.config"/*; do
                if [[ -d "$config_dir" ]]; then
                    dir_name=$(basename "$config_dir")
                    target="$HOME/.config/$dir_name"
                    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$config_dir" ]]; then
                        echo "  .config/$dir_name already linked"
                        continue
                    fi
                    if [[ -e "$target" ]]; then
                        echo "  Backing up existing .config/$dir_name"
                        mv "$target" "$target.backup"
                    fi
                    ln -sf "$config_dir" "$target"
                    echo "  Linked .config/$dir_name"
                fi
            done
        fi
    fi
else
    log_warn "No dotfiles directory found. Create a 'dotfiles' folder with your config files."
fi

# Setup SSH config
SSH_CONFIG_SRC="$DOTFILES_DIR/../ssh_config"
if [[ -f "$SSH_CONFIG_SRC" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cp "$SSH_CONFIG_SRC" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        log_success "SSH config installed"
    elif ! grep -q "# Managed by dotfiles" "$HOME/.ssh/config" 2>/dev/null; then
        echo "" >> "$HOME/.ssh/config"
        echo "# Managed by dotfiles" >> "$HOME/.ssh/config"
        cat "$SSH_CONFIG_SRC" >> "$HOME/.ssh/config"
        log_success "SSH config appended"
    else
        log_success "SSH config already configured"
    fi
fi

# Install Node LTS via fnm
if command_exists fnm; then
    eval "$(fnm env)"
    if fnm list | grep -q "lts-"; then
        log_success "Node LTS already installed"
    else
        echo "Installing Node LTS..."
        fnm install --lts
        fnm default lts-latest
    fi
fi

# Setup git credential helper (platform-specific)
if is_macos; then
    git config --global credential.helper osxkeychain
else
    git config --global credential.helper store
fi

# Setup git config
if [[ -z "$(git config --global user.name)" ]]; then
    if [[ "$HEADLESS" == true ]]; then
        log_warn "Git user.name not configured. Set with: git config --global user.name \"Your Name\""
    else
        echo ""
        echo "🔧 Git configuration required"
        read -p "Enter your git user.name: " git_name
        git config --global user.name "$git_name"
    fi
fi

if [[ -z "$(git config --global user.email)" ]]; then
    if [[ "$HEADLESS" == true ]]; then
        log_warn "Git user.email not configured. Set with: git config --global user.email \"you@example.com\""
    else
        read -p "Enter your git user.email: " git_email
        git config --global user.email "$git_email"
    fi
fi

if [[ -n "$(git config --global user.name)" ]] && [[ -n "$(git config --global user.email)" ]]; then
    log_success "Git configured"
fi

# Setup SSH key
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    if [[ "$HEADLESS" == true ]]; then
        log_warn "No SSH key found. Generate with: ssh-keygen -t ed25519 -C \"your@email.com\""
    else
        echo ""
        echo "🔑 No SSH key found. Generating one..."
        read -p "Enter your email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        log_success "SSH key generated. Add to GitHub: https://github.com/settings/keys"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
    fi
else
    log_success "SSH key already exists"
fi

# Authenticate GitHub CLI
if ! gh auth status &> /dev/null; then
    if [[ "$HEADLESS" == true ]]; then
        log_warn "GitHub CLI not authenticated. Run: gh auth login"
    else
        echo ""
        echo "🔐 GitHub CLI not authenticated"
        read -p "Authenticate now? (y/n): " auth_gh
        if [[ "$auth_gh" == "y" ]]; then
            gh auth login
        fi
    fi
else
    log_success "GitHub CLI authenticated"
fi

# macOS defaults (skip on Linux/headless)
if [[ "$HEADLESS" == false ]] && is_macos; then
    echo "🍎 Setting macOS defaults..."
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.screencapture location -string "$HOME/Desktop"
    defaults write com.apple.screencapture type -string "png"
    log_success "macOS defaults set (some may require logout to take effect)"
fi

echo ""
echo "✨ Bootstrap complete! Reloading shell..."
exec zsh
