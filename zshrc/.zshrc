# load plugins
autoload -U colors; colors
# colored prompt
autoload -U promptinit; promptinit
autoload -Uz vzs_info

# enable autocompletion
autoload -U compinit; compinit
zstyle ':completion:*' menu select
setopt completealiases

# enable comments via #
setopt interactivecomments

# enable edit line
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

typeset -U path

# paths are for winners
path=(
  /usr/local/{bin,sbin}/
  ${HOME}/bin
  $(brew --prefix)/bin
  /usr/bin
  /bin
  $(brew --prefix)/sbin
  /usr/sbin
  /sbin
  /usr/X11/bin
)

# use emacs bindings
bindkey -e

# remember history between sessions
HISTSIZE=1000
if (( ! EUID )); then
  HISTFILE=~/.history_root
else
  HISTFILE=~/.history
fi
SAVEHIST=1000

# ====================
# bindings and aliases
# ====================

# use fasd
if [ $commands[fasd] ]; then # check if fasd is installed
  fasd_cache="$HOME/.fasd-init-cache"
  if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
    fasd --init auto >| "$fasd_cache"
  fi
  source "$fasd_cache"
  unset fasd_cache
  alias v='f -e vim'
  alias o='a -e open'
fi

alias la="ls -A"
alias lt='ls -lhart'
alias ll="ls -lsvAt"
alias git="hub"

# ====================
# program settings
# ====================

LESS="-FXR"
export LESS

EDITOR="nvim"
CLICOLOR=1

VISUAL="$EDITOR"
FCEDIT="$EDITOR"
GIT_EDITOR="$EDITOR"
GEM_EDITOR="$EDITOR"

export FCEDIT VISUAL GIT_EDITOR GEM_EDITOR

alias ls="gls --color=auto"

# ====================
# prompt customization
# ====================

# git
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "on %{$fg[magenta]%}%b%{$reset_color%}%a%m%u%c"
zstyle ':vcs_info:*' stagedstr " %{$fg[green]%}●%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr " %{$fg[red]%}✚%{$reset_color%}"
precmd() {
  vcs_info
}

function check_last_exit_code() {
  local LAST_EXIT_CODE=$?
  local EXIT_CODE_PROMPT=' '
  if [[ $LAST_EXIT_CODE -ne 0 ]]; then
    EXIT_CODE_PROMPT+="%{$fg[red]%}(%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg_bold[red]%}$LAST_EXIT_CODE%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg[red]%}) %t%{$reset_color%}"
  else
    EXIT_CODE_PROMPT+="%{$fg[green]%}%t%{$reset_color%}"
  fi
  echo "$EXIT_CODE_PROMPT"
}

_newline=$'\n'
_lineup=$'\e[1A'
_linedown=$'\e[1B'

setopt prompt_subst
PROMPT='%{$fg[blue]%}%2/%{$reset_color%} ${vcs_info_msg_0_}${_newline}❯ '
RPROMPT='%{${_lineup}%}$(check_last_exit_code)%{${_linedown}%}'


# ====================
# fancy competion
# ====================

# Return if requirements are not found.
if [[ "$TERM" == 'dumb' ]]; then
  return 1
fi

# Add zsh-completions to $fpath.
fpath=("${0:h}/external/src" $fpath)

# Load and initialize the completion system ignoring insecure directories.
autoload -Uz compinit && compinit -i

#
# Options
#

setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt PATH_DIRS           # Perform path search even on command names with slashes.
setopt AUTO_MENU           # Show completion menu on a succesive tab press.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
unsetopt MENU_COMPLETE     # Do not autoselect the first completion entry.
unsetopt FLOW_CONTROL      # Disable start/stop characters in shell editor.

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

FZF_DEFAULT_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor}'"
FZF_CTRL_T_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor}'"
FZF_ALT_C_COMMAND="bfs \( -path '*/vendor' -or -path '*/node_modules' \) -prune -or -type d -nohidden"

# asdf

. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
