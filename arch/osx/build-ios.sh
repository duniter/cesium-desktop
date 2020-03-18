#!/bin/bash

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "/usr/local/opt/nvm/nvm.sh" ]] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm

# Install or update node.js v10
nvm install 10

# Prepare
NVER=`node -v`
CESIUM_TAG=

# Folders
DOWNLOADS="$HOME/Downloads"
RELEASES="$HOME/releases"

mkdir -p "${DOWNLOADS}"

# -----------
# Downloads sources
# -----------

# Remove old sources
#rm -rf "${DOWNLOADS}/cesium_src"

# Get Cesium sources (from git)
if [[ ! -d "$DOWNLOADS/cesium_src" ]]; then
  echo "Downloading Cesium sources into ${DOWNLOADS}/cesium_src ..."
  mkdir -p ${DOWNLOADS} && cd ${DOWNLOADS}
  git clone https://github.com/duniter/cesium.git cesium_src
  if [[ $? -ne 0 ]]; then exit 2; fi

  echo "Installing dependencies..."
  cd cesium_src
  npm install
  if [[ $? -ne 0 ]]; then exit 2; fi

  echo "Restoring cordova plugins..."
  ionic state restore
  if [[ $? -ne 0 ]]; then exit 2; fi
else
  echo "Updating sources in ${DOWNLOADS}/cesium_src ..."
  cd ${DOWNLOADS}/cesium_src
  git fetch
  git checkout origin/master
  if [[ $? -ne 0 ]]; then exit 2; fi
fi

# Read the release tag from source
if [[ ! -f "${DOWNLOADS}/cesium_src/package.json" ]]; then
  echo "Unable to read git tags from source: ${DOWNLOADS}/cesium_src"
  exit 2
fi

# Reading git tag
cd ${DOWNLOADS}/cesium_src
COMMIT=`git rev-list --tags --max-count=1`
CESIUM_TAG=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`

# TODO: checkout the latest tag ?

# -----------
# Releases
# -----------

# Remove old releases
rm -rf /vagrant/cesium-*-ios.app

# Make sure iOS platform exists
if [[ ! -d "$DOWNLOADS/cesium_src/platforms/ios" ]]; then
  cd ${DOWNLOADS}/cesium_src
  ionic platform add ios
fi

# Run build
cd ${DOWNLOADS}/cesium_src
gulp config --env default && gulp
if [[ $? -ne 0 ]]; then exit 2; fi

# Releases
ionic build ios --release
if [[ $? -ne 0 ]]; then exit 2; fi

cd platforms/ios/build/emulator
if [[ $? -ne 0 ]]; then exit 2; fi

zip -r "cesium-v${CESIUM_TAG}-ios.zip" Cesium.app
#zip -r "cesium-v${CESIUM_TAG}-ios.zip" Cesium.app.*
if [[ $? -ne 0 ]]; then exit 2; fi

mv "cesium-v${CESIUM_TAG}-ios.zip" /vagrant
if [[ $? -ne 0 ]]; then exit 2; fi

# TODO: sign the release ?
