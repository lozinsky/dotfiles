#!/usr/bin/env bash

FISH=$(which fish)

if [[ $FISH != $SHELL ]]; then
  echo $FISH | sudo tee -a /etc/shells > /dev/null
  chsh -s $FISH
fi
