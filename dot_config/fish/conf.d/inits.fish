if status --is-interactive
  if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
  end
  if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  end

  zoxide init fish | source

  set --erase ATUIN_NOBIND
  atuin init fish --disable-up-arrow | source
end
