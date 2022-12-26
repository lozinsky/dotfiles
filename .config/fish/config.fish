set -gx DOTFILES "$HOME/.dotfiles"
set -gx GOPATH "$HOME/.go"

set -gx PATH "/opt/homebrew/bin" $PATH
set -gx PATH "$HOME/.cargo/bin" $PATH
set -gx PATH "$GOPATH/bin" $PATH

alias serve "servor --reload"

if type -q asdf
  source (brew --prefix asdf)"/libexec/asdf.fish"
end

starship init fish | source
