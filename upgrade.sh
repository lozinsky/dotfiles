#!/usr/bin/env bash

brew upgrade
brew cask upgrade
brew cleanup

mas upgrade

npm -g outdated
npm -g update --force

rustup self update
rustup update
