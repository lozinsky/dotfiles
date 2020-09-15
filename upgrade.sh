#!/usr/bin/env bash

brew upgrade
brew upgrade --cask
brew cleanup

mas upgrade

npm -g outdated
npm -g update --force

rustup self update
rustup update
