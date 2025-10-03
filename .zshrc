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

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-0
export DISPLAY=:0 

export XDG_CURRENT_DESKTOP=dwl
export DESKTOP_SESSION=dwl

export GTK_THEME="Materia-dark"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export GDK_BACKEND=wayland

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

export MOZ_ENABLE_WAYLAND=1
export MOZ_WEBRENDER=1
export MOZ_DBUS_REMOTE=1

export SDL_VIDEODRIVER=wayland

export _JAVA_AWT_WM_NONREPARENTING=1
export JDK_JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"

export NO_AT_BRIDGE=1 
export ELECTRON_OZONE_PLATFORM_HINT=wayland

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
