#!/bin/bash

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Prepare
NVER=`node -v`
CESIUM_TAG=
NW_VERSION=0.42.2
NW_RELEASE="v${NW_VERSION}"
NW_BASENAME=nwjs
#NW_BASENAME=nwjs-sdk
NW="${NW_BASENAME}-${NW_RELEASE}-linux-x64"
NW_GZ="${NW}.tar.gz"

# Folders
ROOT=`pwd`
DOWNLOADS="$ROOT/downloads"
RELEASES="$ROOT/releases"

mkdir -p "$DOWNLOADS"

# -----------
# Clean sources + releases
# -----------
rm -rf "$DOWNLOADS/cesium"
rm -rf "$DOWNLOADS/cesium_src"
rm -rf "$RELEASES"
rm -rf /vagrant/*.deb
rm -rf /vagrant/*.tar.gz

mkdir -p $DOWNLOADS/cesium

# -----------
# Downloads
# -----------

cd "$DOWNLOADS"

if [[ ! -d "$DOWNLOADS/cesium_src" ]]; then
  git clone https://github.com/duniter/cesium.git cesium_src
fi

cd cesium_src
COMMIT=`git rev-list --tags --max-count=1`
CESIUM_TAG=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`
cd ..

CESIUM_RELEASE="cesium-v$CESIUM_TAG-web"
echo "Checking that Cesium binary has been downloaded"
if [[ ! -e "$DOWNLOADS/$CESIUM_RELEASE.zip" ]]; then
    echo "Have to download it into ${DOWNLOADS}"
    cd cesium

    wget -kL "https://github.com/duniter/cesium/releases/download/v$CESIUM_TAG/$CESIUM_RELEASE.zip"
    unzip $CESIUM_RELEASE.zip
    rm $CESIUM_RELEASE.zip
    cd ..
fi

CESIUM_DEB_VER=" $CESIUM_TAG"
CESIUM_TAG="v$CESIUM_TAG"

# Get NW.js
if [[ ! -d "$DOWNLOADS/$NW" ]]; then
  cd ${DOWNLOADS}
  echo "Downloading ${NW_GZ}..."
  wget -kL https://dl.nwjs.io/${NW_RELEASE}/${NW_GZ}
  tar xvzf ${NW_GZ}
fi

# -----------
# Releases
# -----------

rm -rf "$RELEASES"
mkdir -p "$RELEASES"

cp -r "$DOWNLOADS/cesium" "$RELEASES/cesium"
cd "$RELEASES"

# Releases builds
cd ${RELEASES}/cesium
# Remove git files
rm -Rf .git

# -------------------------------------------------
# Build Desktop version (Nw.js is embedded)
# -------------------------------------------------

## Install Nw.js
mkdir -p "$RELEASES/desktop_release"

# -------------------------------------------------
# Build Desktop version .tar.gz
# -------------------------------------------------

cp -r "$DOWNLOADS/${NW}" "$RELEASES/desktop_release/nw"
cp -r "$DOWNLOADS/cesium" "$RELEASES/desktop_release/nw/"

# Specific desktop files
cp -r /vagrant/package.json "$RELEASES/desktop_release/nw/"
cp -r /vagrant/yarn.lock "$RELEASES/desktop_release/nw/"
cp -r /vagrant/node.js "$RELEASES/desktop_release/nw/cesium"
# Injection
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "$RELEASES/desktop_release/nw/cesium/index.html" || exit 1
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "$RELEASES/desktop_release/nw/cesium/debug.html" || exit 1

# Specific desktop dependencies (for reading Duniter conf, ...)
cd "$RELEASES/desktop_release/nw"
yarn

# Releases
cp -R "$RELEASES/desktop_release" "$RELEASES/desktop_release_tgz"
cd "$RELEASES/desktop_release_tgz"
tar czf /vagrant/cesium-desktop-${CESIUM_TAG}-linux-x64.tar.gz * --exclude ".git" --exclude "coverage" --exclude "test"

# -------------------------------------------------
# Build Desktop version .deb
# -------------------------------------------------

# Create .deb tree + package it
cp -rf "/vagrant/package" "$RELEASES/cesium-x64" || exit 1
mkdir -p "$RELEASES/cesium-x64/opt/cesium/"
chmod 755 ${RELEASES}/cesium-x64/DEBIAN/post*
chmod 755 ${RELEASES}/cesium-x64/DEBIAN/pre*
sed -i "s/Version:.*/Version:$CESIUM_DEB_VER/g" ${RELEASES}/cesium-x64/DEBIAN/control || exit 1
cd ${RELEASES}/desktop_release/nw || exit 1
zip -qr ${RELEASES}/cesium-x64/opt/cesium/nw.nwb *

sed -i "s/Package: .*/Package: cesium-desktop/g" ${RELEASES}/cesium-x64/DEBIAN/control || exit 1
cd ${RELEASES}/ || exit 1
fakeroot dpkg-deb --build cesium-x64 || exit 1
mv cesium-x64.deb /vagrant/cesium-desktop-${CESIUM_TAG}-linux-x64.deb || exit 1
