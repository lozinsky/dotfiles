#!/usr/bin/env bash

brew upgrade
brew cask upgrade

npm -g outdated
npm -g update

rustup self update
rustup update

brew cleanup
