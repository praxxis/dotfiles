alias git 'hub'
alias ls 'eza'
alias ack 'rg --colors path:style:bold --colors line:style:bold --smart-case'
alias fzy 'fzy -l50'
alias cz 'chezmoi'
alias vi 'nvim'
alias dcrun 'docker compose -f /opt/docker-compose.yml '
alias dclogs 'docker compose -f /opt/docker-compose.yml logs -tf --tail="50" '

abbr -a serve 'static-web-server --page-fallback=index.html -d .'
abbr -a ackjs 'ack -g "*.js" -g "*.ts" -g "*.jsx" -g "*.tsx"'
abbr cz-pull 'chezmoi git pull -- --autostash --rebase && chezmoi diff'
abbr cz-commit 'cz git add . && cz git commit -- -m "updates"'
abbr -a stream --set-cursor 'streamlink --player=/Applications/IINA.app/Contents/MacOS/iina-cli --player-args {playerinput}-stdin https://twitch.tv/% best'

alias  hrepo 'command herdr --session (basename (git rev-parse --show-toplevel))'

function ytdl-playlist
    yt-dlp -f "bestvideo+bestaudio/best" \
        --merge-output-format mp4 \
        -o "%(playlist_index)s - %(title)s.%(ext)s" \
        --download-archive archive.txt \
        --cookies-from-browser firefox \
        $argv
end
