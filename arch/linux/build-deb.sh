#!/bin/bash

PROJECT_NAME=cesium
REPO="duniter/cesium"
REPO_PUBLIC_URL="https://github.com/${REPO}"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Prepare
NVER=$(node -v)
NW_VERSION=0.83.0
NW_RELEASE=v${NW_VERSION}
NW_BASENAME=nwjs
#NW_BASENAME=nwjs-sdk
NW=${NW_BASENAME}-${NW_RELEASE}-linux-x64
NW_GZ=${NW}.tar.gz

# Folders
ROOT=$(pwd)
DOWNLOADS=${ROOT}/downloads
RELEASES=${ROOT}/releases

# -----------
# Downloads
# -----------

mkdir -p "${DOWNLOADS}" && cd "${DOWNLOADS}" || exit 1

rm -rf "${DOWNLOADS}/${PROJECT_NAME}"
mkdir -p "${DOWNLOADS}/${PROJECT_NAME}"

if [ ! -d "${DOWNLOADS}/${PROJECT_NAME}_src" ]; then

  git clone ${REPO_PUBLIC_URL}.git ${PROJECT_NAME}_src
  cd ${PROJECT_NAME}_src
else
  cd ${PROJECT_NAME}_src
  git fetch origin --tags
  git reset HEAD
fi

# Get release tag
COMMIT=$(git rev-list --tags --max-count=1)
PROJECT_VERSION=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`
WEB_BASENAME=${PROJECT_NAME}-v${PROJECT_VERSION}-web
WEB_ZIP_FILE=${WEB_BASENAME}.zip

# Compute output base name
if [[ "${NW_BASENAME}" == "nwjs-sdk" ]]; then
  echo "  SDK: true"
  OUTPUT_BASENAME=${PROJECT_NAME}-desktop-v${PROJECT_VERSION}-sdk-linux-x64
else
  OUTPUT_BASENAME=${PROJECT_NAME}-desktop-v${PROJECT_VERSION}-linux-x64
fi

if [ ! -d "${DOWNLOADS}/${WEB_ZIP_FILE}" ]; then
  cd ${DOWNLOADS}
  echo "Downloading ${WEB_ZIP_FILE} into ${DOWNLOADS} ..."
  wget -q "${REPO_PUBLIC_URL}/releases/download/v${PROJECT_VERSION}/${WEB_ZIP_FILE}"

  rm -rf ${PROJECT_NAME} && mkdir -p ${PROJECT_NAME} || exit 1
  unzip -q -o ${WEB_ZIP_FILE} -d "${DOWNLOADS}/${PROJECT_NAME}"
  rm ${WEB_ZIP_FILE}
fi

# Get NW.js
if [[ ! -d "${DOWNLOADS}/${NW}" ]]; then
  cd ${DOWNLOADS}
  echo "Downloading ${NW_GZ}..."
  wget -q "http://dl.nwjs.io/${NW_RELEASE}/${NW_GZ}"
  tar xzf ${NW_GZ}
fi

# -----------
# Releases
# -----------

# Clean previous artifacts
rm -rf "/vagrant/${OUTPUT_BASENAME}.tar.gz"
rm -rf "/vagrant/${OUTPUT_BASENAME}.deb"
rm -rf "/vagrant/${OUTPUT_BASENAME}.AppImage"

# Clean previous releases directory
rm -rf "${RELEASES}"
mkdir -p "${RELEASES}"

# Releases builds
mv "${DOWNLOADS}/${PROJECT_NAME}" "${RELEASES}/" && cd "${RELEASES}/${PROJECT_NAME}" || exit 1

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
ls "${RELEASES}/desktop_release/nw/"

# Copy Cesium desktop sources files
cp -r /vagrant/cesium-desktop.js "${RELEASES}/desktop_release/nw"
cp -r /vagrant/splash.html "${RELEASES}/desktop_release/nw"
cp -r /vagrant/package.json "${RELEASES}/desktop_release/nw/"
cp -r /vagrant/package-lock.json "${RELEASES}/desktop_release/nw/"

# Injection
sed -i 's/<script src="config.js"[^>]*><\/script>/<script src="config.js"><\/script><script src="..\/cesium-desktop.js"><\/script>/' ${RELEASES}/desktop_release/nw/${PROJECT_NAME}/index*.html || exit 1

# Specific desktop dependencies (for reading Duniter conf, ...)
cd "${RELEASES}/desktop_release/nw"
npm install

# Releases
cd "${RELEASES}/desktop_release"
tar czf "/vagrant/${OUTPUT_BASENAME}.tar.gz" *

# -------------------------------------------------
# Build Desktop version .deb
# -------------------------------------------------

# Create .deb tree + package it
cp -r "/vagrant/package" "${RELEASES}/${PROJECT_NAME}-x64" || exit 1
mkdir -p "${RELEASES}/${PROJECT_NAME}-x64/opt/${PROJECT_NAME}/" || exit 1
chmod 755 ${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/post*
chmod 755 ${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/pre*
sed -i "s/Version:.*/Version: ${PROJECT_VERSION}/g" "${RELEASES}/${PROJECT_NAME}-x64/DEBIAN/control" || exit 1
gzip --best -n ${RELEASES}/${PROJECT_NAME}-x64/usr/share/doc/${PROJECT_NAME}-desktop/changelog.* || exit 1

cd "${RELEASES}/desktop_release/nw" || exit 1
zip -qr "${RELEASES}/${PROJECT_NAME}-x64/opt/${PROJECT_NAME}/nw.nwb" *

cd "${RELEASES}/" || exit 1
fakeroot dpkg-deb --build "${PROJECT_NAME}-x64" || exit 1
mv "${PROJECT_NAME}-x64.deb" "/vagrant/${OUTPUT_BASENAME}.deb" || exit 1

rm -rf "${RELEASES}/${PROJECT_NAME}-x64" || exit 1

# -------------------------------------------------
# Build Desktop version .AppImage
# -------------------------------------------------

cp -f /vagrant/appimage/* "${RELEASES}/" || exit 1
cp -f /vagrant/${OUTPUT_BASENAME}.tar.gz "${RELEASES}/" || exit 1
cd "${RELEASES}"
bash -ex ./pkg2appimage appimage.yml || exit 1

OUTPUT_APPIMAGE=$(ls "./out/*.AppImage" | sort -V | tail -n 1)
mv "${OUTPUT_APPIMAGE}" "/vagrant/${OUTPUT_BASENAME}.AppImage" || exit 1

# -------------------------------------------------
# Build Desktop sha256 files
# -------------------------------------------------

cd "/vagrant" || exit 1
sha256sum ${OUTPUT_BASENAME}.tar.gz > ${OUTPUT_BASENAME}.tar.gz.sha256
sha256sum ${OUTPUT_BASENAME}.deb > ${OUTPUT_BASENAME}.deb.sha256
sha256sum ${OUTPUT_BASENAME}.AppImage > ${OUTPUT_BASENAME}.AppImage.sha256

# -------------------------------------------------
# Clean release files
# -------------------------------------------------

rm -rf "${RELEASES}"
