# Fish shell exports converted from bash

set -gx LC_ALL "en_US.UTF-8"
set -gx LANG "en_US.UTF-8"

if test -d "$HOME/bin"
  fish_add_path "$HOME/bin"
end

if test -d "$HOME/bin-private"
  fish_add_path "$HOME/bin-private"
end

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

set -gx PAGER "less"
set -gx LESS '--quit-if-one-screen --ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --tabs=2 --no-init --window=-4'

set -gx HOMEBREW_CASK_OPTS "--appdir=~/Applications --fontdir=/Library/Fonts"

set -gx MANPAGER "sh -c 'col -bx | bat --language man --plain --theme=\"Monokai Extended\"'"
