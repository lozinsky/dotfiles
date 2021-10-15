#!/usr/bin/env bash

if [ ! -n "$DOTFILES" ]; then
  DOTFILES="$HOME/.dotfiles"
fi

$DOTFILES/.command-line-tools
$DOTFILES/.brew
$DOTFILES/.volta
$DOTFILES/.mas
$DOTFILES/.vscode
$DOTFILES/.symlinks
$DOTFILES/.macos
$DOTFILES/.fish
