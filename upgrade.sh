#!/bin/sh

brew upgrade
brew cask upgrade

yarn global upgrade --latest --silent

brew cleanup
