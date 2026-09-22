if test -x /opt/homebrew/bin/brew
  eval (/opt/homebrew/bin/brew shellenv fish)
end
if test -x /home/linuxbrew/.linuxbrew/bin/brew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)
end

if status --is-interactive
  zoxide init fish | source

  set --erase ATUIN_NOBIND
  eval "$(atuin hex init fish)"
  eval "$(atuin init fish --disable-up-arrow)"
end
