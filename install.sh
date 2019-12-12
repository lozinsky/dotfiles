#!/usr/bin/env bash

if [ ! -n "$DOTFILES" ]; then
  DOTFILES="$HOME/.dotfiles"
fi

source "$DOTFILES/.brew"
source "$DOTFILES/.oh-my-zsh"
source "$DOTFILES/.npm"
source "$DOTFILES/.rustup"
source "$DOTFILES/.vscode"
source "$DOTFILES/.symlinks"
source "$DOTFILES/.macos"
