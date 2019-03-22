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
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Ubuntu VM..."
      [[ $? -eq 0 ]] && vagrant up
      [[ $? -eq 0 ]] && echo ">> VM: building Cesium..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-deb.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit 2;
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
      [[ $? -eq 0 ]] && echo ">> Copying Cesium Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/LICENSE.txt ./
      [[ $? -eq 0 ]] && cp ../../src/nw/cesium/node.js ./
      # Win build need a copy of the web asset (download in build.bat failed)
      [[ $? -eq 0 ]] && cp "../../downloads/cesium-v$TAG-web.zip" ./
      if [[ $? -eq 0 && ! -f ./duniter_win7.box ]]; then
        echo ">> Downloading Windows VM..."
        wget -kL https://s3.eu-central-1.amazonaws.com/duniter/vagrant/duniter_win7.box
      fi
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant Windows VM..."
      [[ $? -eq 0 ]] && vagrant up --provision
      if [[ $? -ne 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit 2;
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> Windows binary already built. Ready for upload."
    fi
    ;;
  osx)
    cd arch/osx
    if [[ ! -f "cesium-desktop-v$TAG-osx-x64.zip" ]]; then
      [[ $? -eq 0 ]] && echo ">> Copying Cesium Desktop sources..."
      [[ $? -eq 0 ]] && cp ../../src/nw/yarn.lock ./
      [[ $? -eq 0 ]] && cp ../../src/nw/package.json ./
      [[ $? -eq 0 ]] && cp ../../src/nw/cesium/node.js ./
      # OSx need a copy of the web asset  (download in build-osx.sh failed)
      [[ $? -eq 0 ]] && cp "../../downloads/cesium-v$TAG-web.zip" ./
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant OSx VM..."
      [[ $? -eq 0 ]] && vagrant up --provision
      [[ $? -eq 0 ]] && echo ">> Building Cesium for OSx..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-osx.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit 2;
      else
        echo ">> Build success. Shutting the VM down."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> OSx binaries already built. Ready for upload."
    fi
    ;;
ios)
    cd arch/osx
    if [[ ! -f "cesium-v$TAG-ios.zip" ]]; then
      [[ $? -eq 0 ]] && echo ">> Starting Vagrant OSx VM..."
      [[ $? -eq 0 ]] && vagrant up --provision
      [[ $? -eq 0 ]] && echo ">> Building Cesium for iOS..."
      [[ $? -eq 0 ]] && vagrant ssh -- 'bash -s' < ./build-ios.sh
      if [[ ! $? -eq 0 ]]; then
        echo ">> Something went wrong. Stopping build."
        exit 2;
      else
        echo ">> Build success. Shutting the VM down."
      fi
      vagrant halt
      echo ">> VM closed."
    else
      echo ">> iOS binaries already built. Ready for upload."
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
