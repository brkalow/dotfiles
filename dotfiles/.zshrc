# === SSH Agent ===
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add -q ~/.ssh/id_ed25519 2>/dev/null
fi

# === Remote Detection ===
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    export IS_REMOTE=true
fi

# === History Configuration ===
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# === Shell Options ===
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # push dirs to stack automatically
setopt PUSHD_IGNORE_DUPS    # no duplicate dirs in stack
setopt PUSHD_SILENT         # don't print stack after pushd/popd
setopt CORRECT              # spell correction for commands
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell
setopt NO_BEEP              # no beeping

# === Platform Detection ===
if [[ "$(uname)" == "Darwin" ]]; then
    IS_MACOS=true
    BREW_PREFIX="/opt/homebrew"
    PNPM_HOME="$HOME/Library/pnpm"
    MKCERT_CA="$HOME/Library/Application Support/mkcert/rootCA.pem"
else
    IS_MACOS=false
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
    PNPM_HOME="$HOME/.local/share/pnpm"
    MKCERT_CA="$HOME/.local/share/mkcert/rootCA.pem"
fi

# === PATH Configuration ===
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PNPM_HOME
export PATH="$PNPM_HOME:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# === Editor ===
export EDITOR='cursor'
export VISUAL="$EDITOR"

# === Oh My Zsh ===
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# === Spaceship Prompt (via Homebrew) ===
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_DOCKER_SHOW=false
SPACESHIP_DOCKER_CONTEXT_SHOW=false
[[ -f "$BREW_PREFIX/opt/spaceship/spaceship.zsh" ]] && source "$BREW_PREFIX/opt/spaceship/spaceship.zsh"

# === fzf (fuzzy finder) ===
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
export FZF_CTRL_T_OPTS="--preview 'head -100 {}'"
export FZF_ALT_C_OPTS="--preview 'ls -la {}'"

# === zoxide (better cd) ===
eval "$(zoxide init zsh)"

# === gh CLI completions ===
eval "$(gh completion -s zsh)"

# === fnm (Node Version Manager) ===
eval "$(fnm env --use-on-cd --shell zsh)"

# === bun completions ===
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# === Node CA Certs ===
[[ -f "$MKCERT_CA" ]] && export NODE_EXTRA_CA_CERTS="$MKCERT_CA"

# === direnv ===
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# === Functions ===
clean_be() {
    local ports=(8000 8001 8002 8003 8004 8005 9096 25349)
    for port in "${ports[@]}"; do
        local pid=$(lsof -t -i:"$port")
        if [ -n "$pid" ]; then
            echo "Killing process $pid running on port $port"
            kill "$pid"
        fi
    done
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

port() {
    lsof -i :"$1"
}

killport() {
    local pid=$(lsof -t -i:"$1")
    if [ -n "$pid" ]; then
        kill -9 "$pid" && echo "Killed process $pid on port $1"
    else
        echo "No process on port $1"
    fi
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.tar.xz)  tar xJf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

tre() {
    tree -aC -I '.git|node_modules|.next|dist|build' --dirsfirst "$@" | head -100
}

# === Git Aliases ===
alias g="git"
alias ga="git add"
alias gaa="git add ."
alias gb="git branch"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gci="git commit -n"
alias gcim="git commit -nm"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gco="git checkout"
alias gcf="git checkout -f"
alias gl="git log --oneline --graph --decorate --all"
alias glo="git log --oneline -20"
alias gp="git pull"
alias gpr="git pull --rebase"
alias gpu="git push"
alias gpuf="git push --force-with-lease"
alias gput='git push --set-upstream origin $(git_current_branch)'
alias gs="git status"
alias gss="git status -s"
alias gsw="git switch"
alias gsc="git switch -c"
alias gstp="git stash pop"
alias gstl="git stash list"
alias gd="git diff"
alias gds="git diff --staged"
alias grb="git rebase"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias grs="git restore"
alias grss="git restore --staged"
alias gcl="git clone"

# === Directory Aliases ===
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# === ls Aliases (using eza if available, fallback to ls) ===
if command -v eza &> /dev/null; then
    alias ls="eza --icons"
    alias ll="eza -la --icons --git"
    alias la="eza -a --icons"
    alias lt="eza --tree --level=2 --icons"
else
    alias ll="ls -lah"
    alias la="ls -A"
fi

# === Node Aliases ===
alias nodev="node -v"
alias npmv="npm -v"

# === NPM Aliases ===
alias n="npm"
alias ni="npm install"
alias nid="npm install --save-dev"
alias nis="npm install --save"
alias nr="npm run"
alias nrb="npm run build"
alias nrd="npm run dev"
alias nrc="npm run clean"
alias nrf="npm run format"
alias nrl="npm run lint"
alias nrs="npm run start"
alias nrt="npm run test"
alias nout="npm outdated"

# === PNPM Aliases ===
alias p="pnpm"
alias px="pnpx"
alias pi="pnpm install"
alias pr="pnpm run"
alias prb="pnpm run build"
alias prd="pnpm run dev"
alias prc="pnpm run clean"
alias prf="pnpm run format"
alias prl="pnpm run lint"
alias prs="pnpm run start"
alias prt="pnpm run test"

# === Yalc ===
alias yalc="npx yalc"

# === Yarn Aliases ===
alias y="yarn"
alias yi="yarn install"
alias yr="yarn run"
alias yrd="yarn run dev"
alias yrb="yarn run build"
alias yrs="yarn run start"

# === Bun Aliases ===
alias b="bun"
alias bi="bun install"
alias br="bun run"
alias brd="bun run dev"
alias brb="bun run build"
alias brs="bun run start"
alias brt="bun run test"
alias bx="bunx"

# === Utility Aliases ===
alias c="clear"
alias h="history"
alias j="jobs"
alias reload="exec zsh"
alias path='echo $PATH | tr ":" "\n"'
alias ip="curl -s ipinfo.io | jq"
alias hosts="sudo $EDITOR /etc/hosts"
alias brewup="brew update && brew upgrade && brew cleanup"
alias top="htop 2>/dev/null || top"

# === macOS-specific Aliases ===
if [[ "$IS_MACOS" == true ]]; then
    alias localip="ipconfig getifaddr en0"
    alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
else
    alias localip="hostname -I | awk '{print \$1}'"
    alias flushdns="sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches 2>/dev/null || true"
fi

# === Quick Edit ===
alias zshconfig="$EDITOR ~/.zshrc"
alias ohmyzsh="$EDITOR ~/.oh-my-zsh"
alias gitconfig="$EDITOR ~/.gitconfig"

# === Safety Nets ===
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# === Keybindings ===
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
