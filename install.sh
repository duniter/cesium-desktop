#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp
NW_VERSION=0.42.2
#NW_BASENAME=nwjs
NW_BASENAME=nwjs-sdk
CHROMIUM_MAJOR_VERSION=78
CESIUM_DEFAULT_VERSION=1.4.11

# Check first arguments = version
if [[ $1 =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
then
  VERSION="$1"
  echo "Using Cesium version: $VERSION"
else
  if [[ -f $ROOT_DIR/src/nw/cesium/manifest.json ]];
  then
    VERSION=`grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/cesium/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?"`
  fi

  if [[ $VERSION =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
  then
    echo "Using Cesium detected version: $VERSION"
  else
    VERSION="${CESIUM_DEFAULT_VERSION}";
    echo "No Cesium version detected. Using default: $VERSION"
  fi
fi

# Force nodejs version to 6
if [[ -d "${NVM_DIR}" ]]; then
    . ${NVM_DIR}/nvm.sh
    nvm use 6
else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit 1
fi

# Install NW.js
if [[ ! -f "${ROOT_DIR}/src/nw/nw" ]];
then
  mkdir -p "${TEMP_DIR}" && cd "${TEMP_DIR}" || exit 1
  rm -rf ${TEMP_DIR:?}/* || exit 1
  cd "${TEMP_DIR}" || exit 1
  wget http://dl.nwjs.io/v${NW_VERSION}/${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz
  tar xvzf ${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz || exit 1
  cp -rf ${NW_BASENAME}-v${NW_VERSION}-linux-x64/* "${ROOT_DIR}/src/nw" && rm -rf ${NW_BASENAME}-v${NW_VERSION}-linux-x64 || exit 1
  rm ${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz || exit 1
  rmdir nw

# Check NW version
else
  cd "${ROOT_DIR}/src/nw"
  NW_ACTUAL_VERSION=$(./nw --version | grep nwjs | awk '{print $2}')
  echo "Using Chromium version: ${NW_ACTUAL_VERSION}"
  CHROMIUM_ACTUAL_MAJOR_VERSION=$(echo ${NW_ACTUAL_VERSION} | awk '{split($0, array, ".")} END{print array[1]}')
  cd "${ROOT_DIR}"
  if [[ ${CHROMIUM_ACTUAL_MAJOR_VERSION} -ne ${CHROMIUM_MAJOR_VERSION} ]]; then
    echo "Bad Chromium major version: ${CHROMIUM_ACTUAL_MAJOR_VERSION}. Expected version ${CHROMIUM_MAJOR_VERSION}."
    echo " - try to remove file '$ROOT_DIR/src/nw/nw', then relaunch the script"
    exit 1
  fi
fi

# Instal deps
cd "${ROOT_DIR}/src/nw"
yarn

# Remove old Cesium version
if [[ -f $ROOT_DIR/src/nw/cesium/index.html ]];
then
  OLD_VERSION=$(grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/cesium/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?")
  if [[ ! "$VERSION" = "$OLD_VERSION" ]];
  then
    echo "Removing previous version ${OLD_VERSION}..."
    rm -rf $ROOT_DIR/src/nw/cesium/dist_*
    rm -rf $ROOT_DIR/src/nw/cesium/fonts
    rm -rf $ROOT_DIR/src/nw/cesium/img
    rm -rf $ROOT_DIR/src/nw/cesium/lib
    rm -rf $ROOT_DIR/src/nw/cesium/api
    rm -rf $ROOT_DIR/src/nw/cesium/license
    rm -rf $ROOT_DIR/src/nw/cesium/*.html
    rm -rf $ROOT_DIR/src/nw/cesium/manifest.json
    rm -rf $ROOT_DIR/src/nw/cesium/config.js
  fi
fi

# Install Cesium web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    echo "Downloading Cesium ${VERSION}..."

    mkdir -p "${TEMP_DIR}" && cd "${TEMP_DIR}" || exit 1
    mkdir -p "${TEMP_DIR}/cesium_unzip" && cd "${TEMP_DIR}/cesium_unzip" || exit 1
    wget "https://github.com/duniter/cesium/releases/download/v${VERSION}/cesium-v${VERSION}-web.zip"
    if [[ ! $? -eq 0 ]]; then
        echo "Could not download Cesium web release !"
        exit 1;
    fi
    unzip "cesium-v${VERSION}-web.zip" -d "${TEMP_DIR}/cesium_unzip" || exit 1
    rm "cesium-v${VERSION}-web.zip"

    # Add node.js file into HTML files
    cd ${TEMP_DIR}/cesium_unzip || exit 1
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html" || exit 1

    mv * "${ROOT_DIR}/src/nw/cesium/" || exit 1
    cd ..
    rmdir cesium_unzip
fi

cd ${ROOT_DIR} || exit 1

