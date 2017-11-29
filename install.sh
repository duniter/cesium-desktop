#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp

# Check first arguments = version
if [[ $1 =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
then
  VERSION="$1"
  echo "Using given version: $VERSION"
else
  if [[ -f $ROOT_DIR/src/nw/cesium/manifest.json ]];
  then
    VERSION=`grep -oP "version\": \"\d+.\d+.\d+((a|b)[0-9]+)?\"" $ROOT_DIR/src/nw/cesium/manifest.json | grep -oP "\d+.\d+.\d+((a|b)[0-9]+)?"`
  fi

  if [[ $VERSION =~ ^[0-9]+.[0-9]+.[0-9]+((a|b)[0-9]+)?$ ]];
  then
    echo "Using detected version: $VERSION"
  else
    VERSION="1.0.0";
    echo "No version detected. Using default: $VERSION"
  fi
fi

mkdir -p $TEMP_DIR && cd $TEMP_DIR

# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]];
then
  wget http://dl.nwjs.io/v0.22.3/nwjs-sdk-v0.22.3-linux-x64.tar.gz
  tar xvzf nwjs-sdk-v0.22.3-linux-x64.tar.gz
  mv nwjs-sdk-v0.22.3-linux-x64/* "$ROOT_DIR/src/nw"
  rm nwjs-sdk-v0.22.3-linux-x64.tar.gz
  rmdir nwjs-sdk-v0.22.3-linux-x64
  rmdir nw
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
    rm -rf $ROOT_DIR/src/nw/cesium/*.html
  fi
fi

# Install Cesium web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    echo "Downloading Cesium ${VERSION}..."

    mkdir cesium_unzip && cd cesium_unzip
    wget "https://github.com/duniter/cesium/releases/download/v${VERSION}/cesium-v${VERSION}-web.zip"
    unzip "cesium-v${VERSION}-web.zip"
    rm "cesium-v${VERSION}-web.zip"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "debug.html"
    mv * "$ROOT_DIR/src/nw/cesium/"
    cd ..
    rmdir cesium_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

