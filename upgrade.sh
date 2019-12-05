#!/usr/bin/env bash

brew upgrade
brew cask upgrade

yarn global upgrade --latest --silent

rustup self update
rustup update

brew cleanup
