#!/bin/bash

ROOT_DIR=$PWD
TEMP_DIR=$PWD/tmp

mkdir -p $TEMP_DIR && cd $TEMP_DIR

# Install NW.js
if [[ ! -f $ROOT_DIR/src/nw/nw ]]; then
  wget http://dl.nwjs.io/v0.22.3/nwjs-sdk-v0.22.3-linux-x64.tar.gz
  tar xvzf nwjs-sdk-v0.22.3-linux-x64.tar.gz
  mv nwjs-sdk-v0.22.3-linux-x64/* "$ROOT_DIR/src/nw"
  rm nwjs-sdk-v0.22.3-linux-x64.tar.gz
  rmdir nwjs-sdk-v0.22.3-linux-x64
  rmdir nw
fi

# Install Cesium web
if [[ ! -f $ROOT_DIR/src/nw/cesium/index.html ]]; then
    mkdir cesium_unzip && cd cesium_unzip
    wget https://github.com/duniter/cesium/releases/download/v0.17.0/cesium-v0.17.0-web.zip
    unzip cesium-v0.17.0-web.zip
    rm cesium-v0.17.0-web.zip
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "index.html"
    sed -i 's/<script src="config.js"><\/script>/<script src="config.js"><\/script><script src="node.js"><\/script>/' "debug.html"
    mv * "$ROOT_DIR/src/nw/cesium/"
    cd ..
    rmdir cesium_unzip
fi

cd $ROOT_DIR
rmdir $TEMP_DIR

./src/nw/nw
