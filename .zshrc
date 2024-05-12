export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=( 
    git
    dnf
    zsh-autosuggestions
    zsh-syntax-highlighting
    rust
    golang
    zsh-yarn-completions
)

source $ZSH/oh-my-zsh.sh

# check the dnf plugins commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dnf


# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
pokemon-colorscripts --no-title -s -r

# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# Not supported in the "fish" shell.
(cat ~/.cache/wal/sequences &)

# Alternative (blocks terminal for 0-3ms)
# cat ~/.cache/wal/sequences

# To add support for TTYs this line can be optionally added.
# source ~/.cache/wal/colors-tty.sh

###-begin-flutter-completion-###

if type complete &>/dev/null; then
  __flutter_completion() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           flutter completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F __flutter_completion flutter
elif type compdef &>/dev/null; then
  __flutter_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 flutter completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef __flutter_completion flutter
elif type compctl &>/dev/null; then
  __flutter_completion() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       flutter completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K __flutter_completion flutter
fi

###-end-flutter-completion-##

export PATH="$PATH:$HOME/Development/flutter/bin:$HOME/Development/go/bin/:$HOME/.jdks/corretto-17.0.8.1/bin/"
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
# alias fd="fd --ignore-file=.gitignore"

# kubectl autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion zsh)

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
# /home/monarch/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/plugins/Kotlin/kotlinc/bin/ if kotlin is needed as a command
export PATH="$PATH:$HOME/.pub-cache/bin:$GOPATH/bin/:$HOME/.local/share/JetBrains/Toolbox/scripts/"

alias mongosh="podman exec -it my_mongo mongosh"
function kdeconnect-share {
    kdeconnect-cli --share=$(fzf) --device=d46f60b0_9e03_4e0d_a1d6_6c0646fa98d1
}

alias share="kdeconnect-share"
alias dotfiles='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
alias dotfilesadd='dotfiles add ~/.config/nvim/ ~/.config/sessionizer.sh ~/.config/class.sh \
    ~/.config/project.sh ~/.config/hypr/ ~/.config/waybar/ ~/.config/rofi/ \
    ~/.config/kitty/ ~/.config/wal/ 
    ~/.zshrc ~/.tmux.conf'
alias v="fd --type f --hidden --exclude .git | fzf-tmux -p | xargs --no-run-if-empty nvim"
alias lvim="NVIM_APPNAME=lazy nvim"


export EDITOR="/usr/bin/nvim"

