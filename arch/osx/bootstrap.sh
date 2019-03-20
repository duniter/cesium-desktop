#!/bin/bash

# Create a group 'vagrant'
dscl . append /Users/vagrant GroupMembership vagrant

# Install Homebrew - see http://macappstore.org/nvm/
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null

# System tools
brew update
brew install nvm yarn git zip

brew install thii/unxip/unxip


# User installation
sudo su vagrant -c "bash /vagrant/user-bootstrap.sh"

