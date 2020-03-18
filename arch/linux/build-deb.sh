#!/bin/bash

PROJECT_NAME=cesium
REPO="duniter/cesium"
REPO_PUBLIC_URL="https://github.com/${REPO}"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Prepare
NVER=$(node -v)
TAG=
NW_VERSION=0.42.2
NW_RELEASE="v${NW_VERSION}"
NW_BASENAME=nwjs
#NW_BASENAME=nwjs-sdk
NW="${NW_BASENAME}-${NW_RELEASE}-linux-x64"
NW_GZ="${NW}.tar.gz"

# Folders
ROOT=$(pwd)
DOWNLOADS="${ROOT}/downloads"
RELEASES="${ROOT}/releases"

mkdir -p "${DOWNLOADS}"

# -----------
# Clean sources + releases
# -----------
rm -rf "${DOWNLOADS}/${PROJECT_NAME}"
rm -rf "${RELEASES}"
rm -rf /vagrant/*.deb
rm -rf /vagrant/*.tar.gz

# -----------
# Downloads
# -----------

cd "${DOWNLOADS}"
mkdir -p "${DOWNLOADS}/${PROJECT_NAME}"

if [ ! -d "${DOWNLOADS}/${PROJECT_NAME}_src" ]; then

  git clone ${REPO_PUBLIC_URL}.git ${PROJECT_NAME}_src
  cd ${PROJECT_NAME}_src
else
  cd ${PROJECT_NAME}_src
  git fetch origin
  git reset HEAD
fi

# Get release tag
COMMIT=`git rev-list --tags --max-count=1`
TAG=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`
cd ..

ZIP_BASENAME="${PROJECT_NAME}-v$TAG-web"
echo "Checking that ${PROJECT_NAME} binary has been downloaded"
if [ ! -e "${DOWNLOADS}/${ZIP_BASENAME}.zip" ]; then
    echo "Have to download it into ${DOWNLOADS}"
    cd ${PROJECT_NAME}
    wget -kL "${REPO_PUBLIC_URL}/releases/download/v${TAG}/${ZIP_BASENAME}.zip"
    unzip ${ZIP_BASENAME}.zip
    rm ${ZIP_BASENAME}.zip
    cd ..
fi

DEB_VER=" $TAG"
TAG="v$TAG"

# Get NW.js
if [[ ! -d "${DOWNLOADS}/$NW" ]]; then
  cd ${DOWNLOADS}
  echo "Downloading ${NW_GZ}..."
  wget -kL https://dl.nwjs.io/${NW_RELEASE}/${NW_GZ}
  tar xvzf ${NW_GZ}
fi

# -----------
# Releases
# -----------

rm -rf "${RELEASES}"
mkdir -p "${RELEASES}"

cp -r "${DOWNLOADS}/${PROJECT_NAME}" "${RELEASES}/${PROJECT_NAME}"

# Releases builds
cd "${RELEASES}/${PROJECT_NAME}"
# Remove git files
rm -Rf .git
# Remove unused files (API, maps)
rm -Rf ./api
rm -Rf ./dist_js/*-api.js
rm -Rf ./dist_css/*-api.css
rm -Rf ./maps

# -------------------------------------------------
# Build Desktop version (Nw.js is embedded)
# -------------------------------------------------

## Install Nw.js
mkdir -p "${RELEASES}/desktop_release"

# -------------------------------------------------
# Build Desktop version .tar.gz
# -------------------------------------------------

cp -r "${DOWNLOADS}/${NW}" "${RELEASES}/desktop_release/nw"
cp -r "${RELEASES}/${PROJECT_NAME}" "${RELEASES}/desktop_release/nw/"

# Specific desktop files
cp -r /vagrant/package.json "${RELEASES}/desktop_release/nw/"
cp -r /vagrant/yarn.lock "${RELEASES}/desktop_release/nw/"
cp -r /vagrant/node.js "${RELEASES}/desktop_release/nw/${PROJECT_NAME}"
# Injection
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "${RELEASES}/desktop_release/nw/${PROJECT_NAME}/index.html" || exit 1

# Specific desktop dependencies (for reading Duniter conf, ...)
cd "${RELEASES}/desktop_release/nw"
yarn

# Releases
cp -R "${RELEASES}/desktop_release" "${RELEASES}/desktop_release_tgz"
cd "${RELEASES}/desktop_release_tgz"
tar czf /vagrant/${PROJECT_NAME}-desktop-${TAG}-linux-x64.tar.gz * --exclude ".git" --exclude "coverage" --exclude "test"

# -------------------------------------------------
# Build Desktop version .deb
# -------------------------------------------------

# Create .deb tree + package it
cp -r "/vagrant/package" "${RELEASES}/${PROJECT_NAME}-x64" || exit 1
mkdir -p "${RELEASES}/${PROJECT_NAME}-x64/opt/${PROJECT_NAME}/" || exit 1
chmod 755 ${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/post*
chmod 755 ${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/pre*
sed -i "s/Version:.*/Version:$DEB_VER/g" ${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/control || exit 1
cd "${RELEASES}/desktop_release/nw" || exit 1
zip -qr "${RELEASES}/${PROJECT_NAME}-x64/opt/${PROJECT_NAME}/nw.nwb" *

sed -i "s/Package: .*/Package: ${PROJECT_NAME}-desktop/g" "${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/control" || exit 1
cd ${RELEASES}/ || exit 1
fakeroot dpkg-deb --build "${PROJECT_NAME}-x64" || exit 1
mv "${PROJECT_NAME}-x64.deb" "/vagrant/${PROJECT_NAME}-desktop-${TAG}-linux-x64.deb" || exit 1
