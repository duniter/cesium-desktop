#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp

mkdir -p $TEMP_DIR && cd $TEMP_DIR

# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]]; then
  wget https://dl.nwjs.io/v0.22.3/nwjs-v0.22.3-linux-x64.tar.gz
  tar xvzf nwjs-v0.22.3-linux-x64.tar.gz
  mv nw/* "$ROOT_DIR/src/nw"
  rmdir nw
fi

# Install Cesium web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    mkdir cesium_unzip && cd cesium_unzip
    wget https://github.com/duniter/cesium/releases/download/v0.12.7/cesium-v0.12.7-web.zip
    unzip cesium-v0.12.7-web.zip
    rm cesium-v0.12.7-web.zip
    mv * "$ROOT_DIR/src/nw/cesium/"
    cd ..
    rmdir cesium_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

./src/nw/nw
