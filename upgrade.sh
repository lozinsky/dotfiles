#!/usr/bin/env bash

brew upgrade --no-ask
brew cleanup

npm update -g --min-release-age 2

mise upgrade
