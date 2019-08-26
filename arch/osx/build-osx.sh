#!/bin/bash

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "/usr/local/opt/nvm/nvm.sh" ]] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm

# Install or update node.js v6
nvm install 6

# Prepare
NVER=`node -v`
CESIUM_TAG=
NW_VERSION=0.40.1
NW_RELEASE="v${NW_VERSION}"
NW="nwjs-${NW_RELEASE}-osx-x64"
NW_ZIP="${NW}.zip"

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
if [[ ! -d "${DOWNLOADS}/cesium_src" ]]; then
  echo "Downloading Cesium sources into ${DOWNLOADS}/cesium_src ..."
  mkdir -p ${DOWNLOADS} && cd ${DOWNLOADS}
  git clone https://github.com/duniter/cesium.git cesium_src
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

# -----------
# Downloads binaries
# -----------

# Remove old binaries
rm -rf "${DOWNLOADS}/cesium"

# Get Cesium binaries
if [[ ! -f "${DOWNLOADS}/cesium/index.html" ]]; then
    mkdir -p ${DOWNLOADS}/cesium && cd ${DOWNLOADS}/cesium

    CESIUM_ZIP="cesium-v$CESIUM_TAG-web.zip"
    if [[ -f "/vagrant/${CESIUM_ZIP}" ]]; then
      echo "Unzip Cesium binary into ${DOWNLOADS}/cesium"
      unzip /vagrant/${CESIUM_ZIP} -d ${DOWNLOADS}/cesium
    else
      echo "Downloading ${CESIUM_ZIP} into ${DOWNLOADS} ..."
      curl -fsSL "https://github.com/duniter/cesium/releases/download/v$CESIUM_TAG/${CESIUM_ZIP}" > ${CESIUM_ZIP}
      echo "Unzip Cesium binary into ${DOWNLOADS}/cesium"
      unzip ${CESIUM_ZIP} -d ${DOWNLOADS}/cesium
      rm ${CESIUM_ZIP}
    fi;
fi

# Get NW.js
if [[ ! -d "$DOWNLOADS/$NW" ]]; then
  cd ${DOWNLOADS}
  echo "Downloading ${NW_ZIP}..."
  curl -fsSL "https://dl.nwjs.io/${NW_RELEASE}/${NW_ZIP}" > ${NW_ZIP}
  unzip ${NW_ZIP}
  rm ${NW_ZIP}
fi

# -----------
# Releases
# -----------

# Remove old releases
rm -rf ${RELEASES}
mkdir -p ${RELEASES}
rm -rf /vagrant/cesium-*-osx-x64.zip

# -------------------------------------------------
# Build Desktop version (Nw.js is embedded)
# -------------------------------------------------

## Install Nw.js
cp -r ${DOWNLOADS}/${NW}/* ${RELEASES}/
mkdir -p ${RELEASES}/nwjs.app/Contents/Resources/app.nw/cesium
cp -r ${DOWNLOADS}/cesium/* ${RELEASES}/nwjs.app/Contents/Resources/app.nw/cesium/

# Specific desktop files
cp -f /vagrant/package.json ${RELEASES}/nwjs.app/Contents/Resources/app.nw/
cp -f /vagrant/yarn.lock ${RELEASES}/nwjs.app/Contents/Resources/app.nw/
cp -f /vagrant/node.js ${RELEASES}/nwjs.app/Contents/Resources/app.nw/cesium
cp -rf /vagrant/package/* ${RELEASES}/nwjs.app

# Inject 'node.js' script (in index.html)
cd ${RELEASES}/nwjs.app/Contents/Resources/app.nw/cesium
cat index.html | sed -E 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' > index2.html
rm index.html && mv index2.html index.html
if [[ $? -ne 0 ]]; then exit 2; fi

# Inject 'node.js' script (in debug.html)
cat debug.html | sed -E 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' > debug2.html
rm debug.html && mv debug2.html debug.html
if [[ $? -ne 0 ]]; then exit 2; fi

# Specific desktop dependencies
cd ${RELEASES}/nwjs.app/Contents/Resources/app.nw/cesium
. /usr/local/bin/yarn

cd ${RELEASES}
#FIXME Seems to not work...
mv nwjs.app Cesium.app
if [[ $? -ne 0 ]]; then exit 2; fi

# Releases into a ZIP file
cd ${RELEASES}
zip -r /vagrant/cesium-desktop-v${CESIUM_TAG}-osx-x64.zip Cesium.app nwjs.app
if [[ $? -ne 0 ]]; then exit 2; fi
