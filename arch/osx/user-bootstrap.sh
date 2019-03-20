#!/bin/bash

# Install Homebrew - see http://macappstore.org/nvm/
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null

# System tools
brew update
brew install nvm yarn git zip

brew install thii/unxip/unxip

mkdir -p $HOME/.nvm
export NVM_DIR="$HOME/.nvm"
[[ -s "/usr/local/opt/nvm/nvm.sh" ]] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm

# Create bash profile (useful for debugging from a SSH connection)
if [[ ! -f ${HOME}/.bash_profile ]]; then
  echo "Creating file '${HOME}/.bash_profile'"
  echo "export NVM_DIR=\"\$HOME/.nvm\"" >> $HOME/.bash_profile
  echo "[[ -s \"/usr/local/opt/nvm/nvm.sh\" ]] && \. \"/usr/local/opt/nvm/nvm.sh\"" >> $HOME/.bash_profile
fi

# Node.js
nvm install 6

# node-pre-gyp
npm install -g nw-gyp node-pre-gyp
