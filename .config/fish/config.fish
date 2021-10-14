set -gx DOTFILES "$HOME/.dotfiles"
set -gx GOPATH "$HOME/.go"
set -gx VOLTA_HOME "$HOME/.volta"

set -gx PATH "/opt/homebrew/bin" $PATH
set -gx PATH "$GOPATH/bin" $PATH
set -gx PATH "$VOLTA_HOME/bin" $PATH

alias serve "servor --reload"

starship init fish | source
