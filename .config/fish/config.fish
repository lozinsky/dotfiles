set -gx DOTFILES "$HOME/.dotfiles"
set -gx GOPATH "$HOME/.go"

set -gx PATH "/opt/homebrew/bin" $PATH
set -gx PATH "$GOPATH/bin" $PATH

alias serve "servor --reload"

starship init fish | source
