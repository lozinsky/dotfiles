#!/usr/bin/env bash

brew upgrade
brew cleanup

mas upgrade

npm -g outdated
npm -g update
