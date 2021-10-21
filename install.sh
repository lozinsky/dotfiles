#!/usr/bin/env bash

COMPUTER_NAME="Pavel’s MacBook"
LOCAL_HOST_NAME="honey"

if [ ! -n "$DOTFILES" ]
then
  export DOTFILES="$HOME/.dotfiles"
fi

sudo -v

sudo scutil --set LocalHostName "$LOCAL_HOST_NAME"
sudo scutil --set ComputerName "$COMPUTER_NAME"

if ! pkgutil --packages | grep CL >/dev/null
then
  if xcode-select --print-path &>/dev/null
  then
    sudo rm -rf "$(xcode-select --print-path)"
  fi

  xcode-select --install
  read -s -p "To continue, you need to wait while Command line tools will be installed. Press RETURN if you are done."; echo
fi

if ! which brew >/dev/null
then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  PATH="/opt/homebrew/bin:$PATH"
fi

if ! which starship >/dev/null
then
  brew install starship
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
fi

if ! which fish >/dev/null
then
  brew install fish
  echo "$(which fish)" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$(which fish)"
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES/.config/fish" "$HOME/.config"
  fish "$HOME/.config/fish/config.fish"
fi

"$DOTFILES/.formulae"
"$DOTFILES/.casks"
"$DOTFILES/.macos"

brew cleanup
