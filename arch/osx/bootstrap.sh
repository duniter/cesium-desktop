#!/bin/bash

# Create a group 'vagrant'
dscl . append /Users/vagrant GroupMembership vagrant

# User installation
sudo su vagrant -c "bash /vagrant/user-bootstrap.sh"

