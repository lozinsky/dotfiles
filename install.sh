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

ln -sf "$DOTFILES/.config/zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/.config/zshrc" "$HOME/.zshrc"

source "$HOME/.zshenv"

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
fi

if ! which starship >/dev/null
then
  brew install starship

  mkdir -p "$HOME/.config"

  ln -sf "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
fi

cp "$DOTFILES/.fonts/google-sans-flex/"*.ttf "$HOME/Library/Fonts/"

"$DOTFILES/.formulae"
"$DOTFILES/.casks"
"$DOTFILES/.macos"

brew cleanup
