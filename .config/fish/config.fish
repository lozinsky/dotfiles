set -gx PATH "/opt/homebrew/bin" $PATH

set -gx DOTFILES "$HOME/.dotfiles"
set -gx GOPATH "$HOME/.go"

alias serve "servor --reload"
alias touch-bar-reset "killall ControlStrip"
