#!/bin/bash

# Use SDK, to be able to debug
export NW_BASENAME="nwjs"

PROJECT_DIR=$(pwd)
export VERSION=$1

if [[ "${VERSION}" = "DEV" ]]; then
  # Installing default version
  ./install.sh
  [[ ! $? -eq 0 ]] && exit 1

  # Then copying DEV files
  if [[ -d "${PROJECT_DIR}/../../www/dist" ]]; then
    echo "Copying DEV files..."
    mkdir -p ${PROJECT_DIR}/www/cesium
    mkdir -p ${PROJECT_DIR}/www/cesium/js
    mkdir -p ${PROJECT_DIR}/www/cesium/lib
    cp -rf ${PROJECT_DIR}/../../www/dist/dist_js ${PROJECT_DIR}/www/cesium/dist
    cp -rf ${PROJECT_DIR}/../../www/dist/dist_css ${PROJECT_DIR}/www/cesium/dist
    cp -rf ${PROJECT_DIR}/../../www/js/vendor ${PROJECT_DIR}/www/cesium/js
    cp -rf ${PROJECT_DIR}/../../www/css ${PROJECT_DIR}/www/cesium
    cp -rf ${PROJECT_DIR}/../../www/img ${PROJECT_DIR}/www/cesium
    cp -rf ${PROJECT_DIR}/../../www/lib/ionic ${PROJECT_DIR}/www/cesium/lib/
    cp -rf ${PROJECT_DIR}/../../www/lib/robotodraft ${PROJECT_DIR}/www/cesium/lib/
    cp -rf ${PROJECT_DIR}/../../www/license ${PROJECT_DIR}/www/cesium
    cp -f ${PROJECT_DIR}/../../www/index.html ${PROJECT_DIR}/www/cesium
  fi

else

  ./install.sh $VERSION
  [[ ! $? -eq 0 ]] && exit 1
fi

./www/nw $2 $3
