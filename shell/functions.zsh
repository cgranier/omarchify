# Shell functions ported from Omarchy's default/bash/fns. zsh and bash compatible.
#
# Nothing sources this for you — it is opt-in, since these names may collide with
# what you already have. Try it in the current shell:
#
#     source /path/to/omarchify/shell/functions.zsh
#
# To keep it, add that line to your ~/.zshrc (or ~/.bashrc).
#
# NAME COLLISIONS: zsh refuses to define a function over an existing alias, and
# fails at *parse* time — one collision kills this whole file and every function
# after it. oh-my-zsh's git plugin is the usual culprit. Check before adding:
#
#     zsh -ic 'alias NAME; whence -w NAME'
#
# Omarchy's `ga`/`gd` are `gwa`/`gwd` here for exactly that reason.

# --- SSH port forwarding ------------------------------------------------------
# Forward remote ports to localhost, so localhost:3000 reaches nyc-dev:3000 with
# the secure-context privileges that web sockets and service workers need.
#   fip myhost 3000 8080     dip 3000     lip
fip() {
  (( $# < 2 )) && { echo "Usage: fip <host> <port>..."; return 1; }
  local host=$1 port
  shift
  for port in "$@"; do
    ssh -f -N -L "${port}:localhost:${port}" "$host" \
      && echo "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  (( $# == 0 )) && { echo "Usage: dip <port>..."; return 1; }
  local port pid killed
  for port in "$@"; do
    killed=0
    # Match on the exact -L argument. Deliberately not `pkill -f`, which happily
    # matches the shell that invoked it.
    for pid in $(pgrep -x ssh); do
      if tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q -- "-L ${port}:localhost:${port}"; then
        kill "$pid" 2>/dev/null && { echo "Stopped forwarding port $port"; killed=1; }
      fi
    done
    (( killed )) || echo "No forwarding on port $port"
  done
}

lip() {
  local pid found=0
  for pid in $(pgrep -x ssh); do
    local cmd
    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    case $cmd in *-L\ [0-9]*:localhost:*) echo "$pid: $cmd"; found=1 ;; esac
  done
  (( found )) || echo "No active forwards"
}

# --- rsync-on-change watchers -------------------------------------------------
# Needs inotify-tools.  rsw ~/Work/app myhost:Work/app
rsw() {
  (( $# != 2 )) && { echo "Usage: rsw <source> <destination>"; return 1; }
  command -v inotifywait >/dev/null || { echo "rsw needs inotify-tools"; return 1; }
  local src=${1%/} dest=$2
  local sockets=${XDG_RUNTIME_DIR:-$HOME/.ssh/sockets}
  mkdir -p "$sockets"
  local rsh="ssh -o ControlMaster=auto -o ControlPath=$sockets/rsw-%r@%h:%p -o ControlPersist=yes"
  setsid --fork env RSYNC_RSH="$rsh" bash -c \
    'rsync -a "$1/" "$2"; while inotifywait -r -q -e modify,create,delete,move "$1"; do rsync -a "$1/" "$2"; done' \
    rsw-watch "$src" "$dest" >/dev/null 2>&1
  echo "Watching $src -> $dest"
}

lsw() {
  local pid cmd rest found=0
  while read -r pid cmd; do
    rest=${cmd##*rsw-watch }
    echo "$pid: ${rest% *} -> ${rest##* }"
    found=1
  done < <(pgrep -af 'rsw-watch ')
  (( found )) || echo "No active watches"
}

dsw() {
  local pid found=0
  for pid in $(pgrep -f 'rsw-watch '); do
    kill -- -"$pid" 2>/dev/null && { echo "Stopped watch (pid $pid)"; found=1; }
  done
  (( found )) || echo "No active watches"
}

# --- git worktrees ------------------------------------------------------------
# gwa makes a worktree beside the repo and jumps in; gwd removes the one you are in.
#
# Omarchy names these `ga` and `gd`, which collide with oh-my-zsh's git plugin
# (`ga='git add -A'`, `gd='git diff'`) — and zsh refuses to define a function over
# an existing alias, so sourcing this file would die with a parse error and take
# every other function down with it. Renamed to gwa/gwd (git worktree add/drop).
#
# Also drops Omarchy's `mise trust` (not used here) and replaces `gum confirm`
# (not installed) with a plain prompt.
gwa() {
  [[ -n $1 ]] || { echo "Usage: gwa <branch>"; return 1; }
  local branch=$1 base wt
  base=$(basename "$PWD")
  wt="../${base}--${branch}"
  git worktree add -b "$branch" "$wt" && cd "$wt" || return 1
}

gwd() {
  local cwd worktree root branch reply
  cwd=$PWD
  worktree=$(basename "$cwd")
  root=${worktree%%--*}
  branch=${worktree#*--}
  [[ $root != "$worktree" ]] || { echo "Not in a gwa-created worktree"; return 1; }
  printf 'Remove worktree %s and branch %s? [y/N] ' "$worktree" "$branch"
  read -r reply
  [[ $reply == [yY]* ]] || return 0
  cd "../$root" || return 1
  git worktree remove "$cwd" --force || return 1
  git branch -D "$branch"
}

# --- misc ---------------------------------------------------------------------
compress()   { tar -czf "${1%/}.tar.gz" "${1%/}"; }
# A function, not Omarchy's alias: zsh parses a whole `-c` line before source
# runs, so an alias defined there is invisible to scripts.
decompress() { tar -xzf "$1"; }

# Ubuntu ships bat as batcat and fd as fdfind.
command -v bat >/dev/null || { command -v batcat >/dev/null && alias bat=batcat; }
command -v fd  >/dev/null || { command -v fdfind >/dev/null && alias fd=fdfind; }
