bindkey -v

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

alias ls='ls --color=auto -a'


function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]] || [[ $1 == block ]]; then
    echo -ne '\e[1 q'
  elif [[ $KEYMAP == main ]] || [[ $KEYMAP == viins ]] || [[ -z $KEYMAP ]] || [[ $1 == beam ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

preexec() { echo -ne '\e[5 q'; }

echo -ne '\e[5 q'

PROMPT='%F{blue}%~%f %# '

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

export PATH="$HOME/.local/bin:$PATH"
export GTK_THEME="Materia-dark"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  export XDG_CURRENT_DESKTOP=dwl
  export MOZ_ENABLE_WAYLAND=1
  export MOZ_WEBRENDER=1
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
