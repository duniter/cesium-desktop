#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp
NV_VERSION=0.35.3
CHROMIUM_MAJOR_VERSION=71
CESIUM_DEFAULT_VERSION=1.2.9

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
if [[ -d "$NVM_DIR" ]]; then
    . $NVM_DIR/nvm.sh
    nvm use 6
else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit -1
fi

mkdir -p $TEMP_DIR && cd $TEMP_DIR


# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]];
then
  #NV_BASENAME=nwjs
  NV_BASENAME=nwjs-sdk
  wget http://dl.nwjs.io/v${NV_VERSION}/${NV_BASENAME}-v${NV_VERSION}-linux-x64.tar.gz
  tar xvzf ${NV_BASENAME}-v${NV_VERSION}-linux-x64.tar.gz
  mv ${NV_BASENAME}-v${NV_VERSION}-linux-x64/* "$ROOT_DIR/src/nw"
  rm ${NV_BASENAME}-v${NV_VERSION}-linux-x64.tar.gz
  rmdir ${NV_BASENAME}-v${NV_VERSION}-linux-x64
  rmdir nw

  cd $ROOT_DIR/src/nw
  yarn

# Check NW version
else
  cd ${ROOT_DIR}/src/nw
  yarn

  NW_ACTUAL_VERSION=`./nw --version | grep nwjs | awk '{print $2}'`
  echo "Using Chromium version: ${NW_ACTUAL_VERSION}"
  CHROMIUM_ACTUAL_MAJOR_VERSION=`echo ${NW_ACTUAL_VERSION} | awk '{split($0, array, ".")} END{print array[1]}'`
  cd ${ROOT_DIR}
  if [[ ${CHROMIUM_ACTUAL_MAJOR_VERSION} -ne ${CHROMIUM_MAJOR_VERSION} ]]; then
    echo "Bad Chromium major version: ${CHROMIUM_ACTUAL_MAJOR_VERSION}. Expected version ${CHROMIUM_MAJOR_VERSION}"
    exit -1
  fi
fi

# Remove old Cesium version
if [[ -f $ROOT_DIR/src/nw/cesium/index.html ]];
then
  OLD_VERSION=`grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/cesium/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?"`
  if [[ ! "$VERSION" = "$OLD_VERSION" ]];
  then
    rm -rf $ROOT_DIR/src/nw/cesium/dist_*
    rm -rf $ROOT_DIR/src/nw/cesium/fonts
    rm -rf $ROOT_DIR/src/nw/cesium/img
    rm -rf $ROOT_DIR/src/nw/cesium/lib
    rm -rf $ROOT_DIR/src/nw/cesium/api
    rm -rf $ROOT_DIR/src/nw/cesium/license
    rm -rf $ROOT_DIR/src/nw/cesium/*.html
  fi
fi

# Install Cesium web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    echo "Downloading Cesium ${VERSION}..."

    mkdir -p ${TEMP_DIR}/cesium_unzip
    wget "https://github.com/duniter/cesium/releases/download/v${VERSION}/cesium-v${VERSION}-web.zip"
    if [[ ! $? -eq 0 ]]; then
        echo "Could not download Cesium web release !"
        exit -1;
    fi
    unzip "cesium-v${VERSION}-web.zip" -d ${TEMP_DIR}/cesium_unzip
    rm "cesium-v${VERSION}-web.zip"

    # Add node.js file into HTML files
    cd ${TEMP_DIR}/cesium_unzip
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "debug.html"

    mv * "$ROOT_DIR/src/nw/cesium/"
    cd ..
    rmdir cesium_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

