#!/bin/bash

XCODE_VERSION=8.2.1
XCODE_XIP_FILE="Xcode_${XCODE_VERSION}.xip"

if [[ ! -f "/usr/local/bin/brew" ]]; then
  echo "Installing Homebrew..."
  # Install Homebrew - see http://macappstore.org/nvm/
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
fi;

# System tools
brew update
if [[ $? -ne 0 ]]; then exit 2; fi
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
if [[ $? -ne 0 ]]; then exit 2; fi

# node-pre-gyp
npm install -g nw-gyp node-pre-gyp
if [[ $? -ne 0 ]]; then exit 2; fi

# Make sure XCode XIP file exists
if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo "Installing XCode ${XCODE_VERSION}..."

  if [[ ! -f /vagrant/${XCODE_XIP_FILE} ]]; then
    echo "ERROR: Could not install Xcode: file '${XCODE_XIP_FILE}' not found"
    echo "Please, make sure to:"
    echo " - Download at: https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_${XCODE_VERSION}/Xcode_${XCODE_VERSION}.xip (Need an apple account)"
    echo " - Copy '${XCODE_XIP_FILE}' into 'platforms/desktop/arch/osx'"
    echo " - then relaunch the build"
    exit 2
  fi

  cd /vagrant
  unxip ${XCODE_XIP_FILE}
  if [[ $? -ne 0 ]]; then exit 2; fi

  echo "Moving XCode into /Applications"
  sudo mv Xcode.app /Applications
  if [[ $? -ne 0 ]]; then exit 2; fi

  echo "Configuring 'xcode-select' to use Xcode"
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  if [[ $? -ne 0 ]]; then exit 2; fi
fi

exit 0
