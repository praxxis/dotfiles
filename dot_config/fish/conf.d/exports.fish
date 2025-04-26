# Fish shell exports converted from bash

set -gx LC_ALL "en_US.UTF-8"
set -gx LANG "en_US"

if test -d "$HOME/bin"
    fish_add_path "$HOME/bin"
end

if test -d "$HOME/bin-private"
    fish_add_path "$HOME/bin-private"
end

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

set -gx LESS '--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4'

set -gx HOMEBREW_CASK_OPTS "--appdir=~/Applications --fontdir=/Library/Fonts"