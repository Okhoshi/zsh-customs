# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
MIDDLE_BG='NONE'
SEGMENT_SEPARATOR=''
SEGMENT_SEPARATOR_RIGHT=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# Set the bg color for rprompt
function prompt_start() {
	[[ -n $MIDDLE_BG ]] && MIDDLE_BG="%K{$MIDDLE_BG%}" || MIDDLE_BG="%k"
	echo -n "%{$MIDDLE_BG%}"
}

# Begin a segment in rprompt
function prompt_segment_right() {
	local bg fg bbg
	if [[ -n $1 ]]; then
		bg="%K{$1}"
		bbg="%F{$1}"
	else
		bg="%k"
		bbg="%f"
	fi
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	echo -n " %{$bbg%}$SEGMENT_SEPARATOR_RIGHT%{$fg$bg%} "
	[[ -n $3 ]] && echo -n "$3%{$fg$bg%}"
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git_old() {
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:git:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\// }${vcs_info_msg_0_%% }${mode}"
  fi
}

# Git: branch, dirty status, commits behind/ahead of remote
function prompt_git() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    local ref dirty mode repo_path branch icons
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    dirty=$(parse_git_dirty)

    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
      prompt_segment red white
    elif [[ -n $dirty ]]; then
      prompt_segment yellow black
      (( STATUSBAR_LENGTH += 2 ))
    else
      prompt_segment green black
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
      (( STATUSBAR_LENGTH += 4 ))
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
      ((STATUSBAR_LENGTH += 4 ))
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
      (( STATUSBAR_LENGTH += 4 ))
    fi

    branch="${ref/refs\/heads\// }"
    icons="$dirty$(helper_git_remote_status)$mode"
    echo -n $branch$icons
    # Add length of git status, including a space and an arrow, to STATUSBAR_LENGTH
    (( STATUSBAR_LENGTH += $#branch + $#icons + 2 ))

  fi
}

# Helper function: determine commits behind/ahead of remote
function helper_git_remote_status() {
  if [[ -n ${$(command git rev-parse --verify ${hook_com[git_branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} ]]; then
    ahead=$(command git rev-list ${hook_com[git_branch]}@{upstream}..HEAD 2>/dev/null | wc -l | xargs echo)
    behind=$(command git rev-list HEAD..${hook_com[git_branch]}@{upstream} 2>/dev/null | wc -l | xargs echo)

    if [ $behind -gt 0 ]; then
      (( STATUSBAR_LENGTH += $#behind + 2 ))
      echo -n " ↓$behind"
    fi
    if [ $ahead -gt 0 ]; then
      (( STATUSBAR_LENGTH += $#ahead + 2 ))
      echo -n " ↑$ahead"
    fi
  fi
}

function helper_git_commit_hash() {
  hash=$(command git rev-parse --short HEAD)
  (( STATUSBAR_LENGTH += $#hash + 1 ))
  echo -n "#$hash"
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^(M|A)"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}


# Dir: current working directory, shortens if longer than available space
function prompt_dir {
  local termwidth=$(helper_count_spacing)
  if [[ ${#${(%):-%~}} -gt ${termwidth} ]]; then
    prompt_segment blue white "%${termwidth}<…<%~%<<"
  else
    prompt_segment blue white ${(%):-%~}
  fi
  # ${param:-value} means use param if non-zero length, else value
  # In this context, it should use (%) before %~
  # ${(C)__string__} capitalizes the first character of each word, zsh style
}


# Helper function: count the spaces available for printing the working directory
function helper_count_spacing {
  # Store substituted string of trimmed time and history count
  local temp="$(echo $(print -nP %t%!))"
  # From the total width, subtract spaces, left-side length without working directory, (trimmed) time + space, and history count
  echo $(( ${COLUMNS} - $STATUSBAR_LENGTH - $#temp - 1 ))
}


# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment yellow black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment_right black default "$symbols"
}

prompt_git_hash() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    hash=$(helper_git_commit_hash)
    prompt_segment_right cyan white "$hash"
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_virtualenv
  prompt_end
}

BATTERY_COLOR_RESET='%{%F{blue}%K{white}%}'
BATTERY_GAUGE_SLOTS=6
BATTERY_GREEN_THRESHOLD=3
BATTERY_YELLOW_THRESHOLD=1

statusbar_right() {
  RETVAL=$?
  prompt_start
  prompt_status
  prompt_git_hash
  if [[ $(battery_pct) =~ [0-9]+ ]]; then
    prompt_segment_right white blue $(battery_level_gauge)
  else
    prompt_segment_right white blue $(battery_pct_prompt)
  fi    
  
  prompt_segment_right black white %D{%H:%M:%S}
}

# %b = , %f = default foreground, %k = default background, %K = bg color, %F = fg text color, %B = , %E = (apply formatting until) end of line

PROMPT='%{%f%b%k%}$(build_prompt)%E '
RPROMPT='$(statusbar_right) '
