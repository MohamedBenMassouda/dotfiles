ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Install zinit
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
fi

source $ZINIT_HOME/zinit.zsh
eval "$(starship init zsh)"

zinit light zdharma-continuum/fast-syntax-highlighting/
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

fpath=(
   $fpath
   $HOME/.local/share/zsh/generated_man_completions
)

# Load completions
autoload -Uz compinit && compinit

setopt autocd
# Vi mode
bindkey -v

zinit cdreplay -q

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::kubectl
zinit snippet OMZP::command-not-found

zstyle ':completion:*' menu select

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# /home/monarch/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/plugins/Kotlin/kotlinc/bin/ if kotlin is needed as a command
export PATH="$PATH:$HOME/Development/flutter/bin:$HOME/.pub-cache/bin:$GOPATH/bin/:$HOME/.local/share/JetBrains/Toolbox/scripts/"
alias docker="sudo docker"
export PROJECT="$HOME/.config/project.sh"
export SESSIONEZ="$HOME/.config/sessionizer.sh"
export GOPATH="$HOME/go/"
alias gogrep="$GOPATH/bin/gogrep"
alias class="~/.config/class.sh"
alias proj="$PROJECT"
alias sess="$SESSIONEZ"
alias k="kubectl"
alias rg="rg -g '!{**/node_modules/*,**/.git/*, **/venv/*}' --hidden --follow"

function fuzzy_nvim_start {
    if [ "$#" -eq 0 ]; then
        # nvim +'Telescope find_files hidden=false layout_config={height=0.9}'
        nvim +'FzfLua files hidden=false layout_config={height=0.9}'
    elif [ -d "$1" ]; then
        nvim +"Telescope find_files hidden=false layout_config={height=0.9} cwd=$1"
    else
        nvim $@
    fi
}
alias nv='fuzzy_nvim_start'

alias mongosh="podman exec -it my_mongo mongosh"
function kdeconnect-share {
    kdeconnect-cli --share=$(fzf) --device=d46f60b0_9e03_4e0d_a1d6_6c0646fa98d1
}

alias share="kdeconnect-share"
alias dotfiles='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
alias dotfilesadd='dotfiles add ~/.config/nvim/ ~/.config/sessionizer.sh ~/.config/class.sh \
    ~/.config/project.sh ~/.config/hypr/ ~/.config/waybar/ ~/.config/rofi/ \
    ~/.config/kitty/ ~/.config/wal/  ~/.config/swaync/ ~/.config/swappy/ ~/.config/wlogout/ \
    ~/.zshrc ~/.tmux.conf'
alias v="fd --type f --hidden --exclude .git | fzf-tmux -p | xargs --no-run-if-empty nvim"
alias lvim="NVIM_APPNAME=lazy nvim"
alias poetry="~/.local/bin/poetry"
alias ls="ls --color=auto"

export EDITOR="/usr/bin/nvim"
export KEYTIMEOUT=1
export VISUAL=nvim

source <(fzf --zsh)
alias clipman="~/Git/clipman/clipman"

export FZF_DEFAULT_COMMAND='rg --files --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"


bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
unset zle_bracketed_paste

# Enable incremental history search
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
export CHROME_EXECUTABLE="/var/lib/flatpak/app/com.google.Chrome/x86_64/stable/active/export/bin/com.google.Chrome"
