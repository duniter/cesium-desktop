#!/bin/bash

TAG="$3"

case "$1" in
make)
  case "$2" in
  linux)
    cd arch/linux
    if [[ ! -f "cesium-desktop-v$TAG-linux-x64.deb" ]]; then
      [[ $? -eq 0 ]] && echo ">> Copying Cesium Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/yarn.lock ./
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/cesium/node.js ./
      [[ $? -eq 0 ]] && cp "../../downloads/cesium-v$TAG-web.zip" ./
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Ubuntu VM..."
      [[ $? -eq 0 ]] && vagrant up
      [[ $? -eq 0 ]] && echo ">> VM: building Cesium..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-deb.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit -1;
      else
        echo ">> Build success. Shutting the VM down."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Debian binaries already built. Ready for upload."
    fi
    ;;
  win)
    cd arch/windows
    if [[ ! -f "cesium-desktop-v$TAG-windows-x64.exe" ]]; then
      CESIUM_RELEASE="cesium-v$CESIUM_TAG-web"
      [[ $? -eq 0 ]] && echo ">> Copying Cesium Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/LICENSE.txt ./
      [[ $? -eq 0 ]] && cp ../../src/nw/cesium/node.js ./
      [[ $? -eq 0 ]] && cp "../../downloads/cesium-v$TAG-web.zip" ./
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Windows VM..."
      [[ $? -eq 0 ]] && vagrant up
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit -1;
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Windows binary already built. Ready for upload."
    fi
    ;;
  osx)
    cd arch/osx
    if [[ ! -f "cesium-desktop-v$TAG-osx.zip" ]]; then
      [[ $? -eq 0 ]] && echo ">> Copying Cesium Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/yarn.lock ./
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/cesium/node.js ./
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Ubuntu VM..."
      [[ $? -eq 0 ]] && vagrant up
      [[ $? -eq 0 ]] && echo ">> VM: building Cesium..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-osx.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit -1;
      else
        echo ">> Build success. Shutting the VM down."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Debian binaries already built. Ready for upload."
    fi
    ;;
  *)
    echo "Unknown binary « $2 »."
    ;;
  esac
    ;;
*)
  echo "Unknown task « $1 »."
  ;;
esac
