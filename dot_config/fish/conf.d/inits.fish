if status --is-interactive
  eval (/opt/homebrew/bin/brew shellenv)
  zoxide init fish | source

  set --erase ATUIN_NOBIND
  atuin init fish --disable-up-arrow | source
end
