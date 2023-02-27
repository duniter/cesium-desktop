# Cesium Desktop packager

## Test a release

This script will run Cesium Desktop, taking care of installing Cesium + Nw.js if necessary.

    ./run.sh

## Produce new release

### Setup your environment

#### Authentication token

**Requires your GITHUB token with full access to `repo`** to be stored in clear in `$HOME/.config/cesium/.github` text file.

> You can create such a token at https://github.com/settings/tokens > "Generate a new token". Then copy the token and paste it in the file.

#### Install Virtualbox and Vagrant

The release script use some Vagrant, and a VM running into VirtualBox.

- Install VirtualBox
- Install the VirtualBox Extension Pack (need by OSx build, for USB support).
- Install vagrant : `sudo apt-get install vagrant`

### Execute release script

This script will produce for a given `TAG`:

* check that the `TAG` exists on remote GitHub repository
* eventually create the pre-release if it does not exist
* produce Linux and Windows releases of Cesium Desktop and upload them

To produce `TAG` 1.3.7:

    ./release.sh 1.3.7

