 #!/bin/bash

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "/usr/local/opt/nvm/nvm.sh" ]] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm


nvm install 6

# Prepare
NVER=`node -v`
CESIUM_TAG=
NW_VERSION=0.35.4
NW_RELEASE="v${NW_VERSION}"
NW="nwjs-${NW_RELEASE}-osx-x64"
NW_ZIP="${NW}.zip"

# Folders
ROOT=`pwd`
DOWNLOADS="$ROOT/Downloads"
RELEASES="$ROOT/releases"

mkdir -p "$DOWNLOADS"


# -----------
# Clean sources + releases
# -----------
rm -rf "$DOWNLOADS/cesium"
#rm -rf "$DOWNLOADS/cesium_src"
rm -rf "$RELEASES"
# Remove old release
rm -rf ${RELEASES}/cesium-*-osx-x64.zip
#rm -rf /vagrant/cesium-*-osx-x64.zip

# -----------
# Downloads
# -----------
if [[ ! -d "$DOWNLOADS/cesium_src" ]]; then
  mkdir -p ${DOWNLOADS} && cd ${DOWNLOADS}
  git clone https://github.com/duniter/cesium.git cesium_src
fi

# Read the release tag from source
if [[ ! -f "${DOWNLOADS}/cesium_src/package.json" ]]; then
  echo "Unable to read git tags from source: ${DOWNLOADS}/cesium_src"
  exit 2
fi

cd ${DOWNLOADS}/cesium_src
COMMIT=`git rev-list --tags --max-count=1`
CESIUM_TAG=`echo $(git describe --tags $COMMIT) | sed 's/^v//'`

# Get Cesium binaries
if [[ ! -f "${DOWNLOADS}/cesium/index.html" ]]; then
    mkdir -p ${DOWNLOADS}/cesium && cd ${DOWNLOADS}/cesium

    CESIUM_ZIP="cesium-v$CESIUM_TAG-web.zip"
    if [[ -f "/vagrant/${CESIUM_ZIP}" ]]; then
      echo "Unzip Cesium binary into ${DOWNLOADS}/cesium"
      unzip /vagrant/${CESIUM_ZIP} -d ${DOWNLOADS}/cesium
    else
      echo "Downloading ${CESIUM_ZIP} into ${DOWNLOADS}..."
      curl -fsSL "https://github.com/duniter/cesium/releases/download/v$CESIUM_TAG/${CESIUM_ZIP}" > ${CESIUM_ZIP}
      echo "Unzip Cesium binary into ${DOWNLOADS}/cesium"
      unzip ${CESIUM_ZIP} -d ${DOWNLOADS}/cesium
      rm ${CESIUM_ZIP}
    fi;
fi

if [[ ! -f "$DOWNLOADS/$NW_ZIP" ]]; then
  echo "Downloading ${NW_ZIP}..."
  cd ${DOWNLOADS}
  curl -fsSL "https://dl.nwjs.io/${NW_RELEASE}/${NW_ZIP}" > ${NW_ZIP}
  unzip ${NW_ZIP}
fi

# -----------
# Releases
# -----------

mkdir -p ${RELEASES}
rm -rf ${RELEASES}/*

# -------------------------------------------------
# Build Desktop version (Nw.js is embedded)
# -------------------------------------------------

## Install Nw.js
cp -r ${DOWNLOADS}/${NW}/* ${RELEASES}/
cp -r ${DOWNLOADS}/cesium ${RELEASES}/nwjs.app/Contents/Resources/cesium

# Specific desktop files
cp -r /vagrant/package.json ${RELEASES}/nwjs.app/Contents/Resources/
cp -r /vagrant/yarn.lock ${RELEASES}/nwjs.app/Contents/Resources/
cp -r /vagrant/node.js ${RELEASES}/nwjs.app/Contents/Resources/cesium

# Inject 'node.js' script
cd $RELEASES/desktop_release/nw/cesium/
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' index.html
sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' debug.html

# Specific desktop dependencies (for reading Duniter conf, ...)
cd "$RELEASES/nwjs.app/Contents/Resources"
yarn

# Releases
cd $RELEASES
zip cesium-desktop-v${CESIUM_TAG}-osx64-x64.zip $RELEASES/*
#rm -rf $RELEASES/nwjs.app
