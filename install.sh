#!/bin/sh

if [ ! -n "$DOTFILES" ]; then
  DOTFILES="$HOME/.dotfiles"
fi

source "$DOTFILES/.brew"
source "$DOTFILES/.oh-my-zsh"
source "$DOTFILES/.yarn"
source "$DOTFILES/.vscode"
source "$DOTFILES/.symlinks"
source "$DOTFILES/.macos"