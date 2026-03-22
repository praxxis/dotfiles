set -U fish_greeting
fish_config theme choose "Dracula Official"

# allow overriding binaries by having this first in PATH
if test -d "$HOME/bin-private"
  fish_add_path -m "$HOME/bin-private"
end
