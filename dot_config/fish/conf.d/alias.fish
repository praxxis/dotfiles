alias git 'hub'
alias ls 'eza'
alias ack 'rg --colors path:style:bold --colors line:style:bold --smart-case'
alias fzy 'fzy -l50'
alias cz 'chezmoi'
alias vi 'nvim'

abbr -a serve 'static-web-server --page-fallback=index.html -d .'
abbr -a ackjs 'ack -g "*.js" -g "*.ts" -g "*.jsx" -g "*.tsx"'
abbr cz-pull 'chezmoi git pull -- --autostash --rebase && chezmoi diff'
abbr cz-commit 'cz git add . && cz git commit -- -m "updates"'