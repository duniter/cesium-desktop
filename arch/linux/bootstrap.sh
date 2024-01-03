#!/bin/bash

# System tools
apt update
# Deps need for tar.gz and .deb build
apt install --yes git curl python3-minimal zip fakeroot
# Deps need for AppImage build
apt install --yes imagemagick desktop-file-utils binutils

# User installation
sudo su vagrant -c "bash /vagrant/user-bootstrap.sh"
