#!/bin/bash

PROJECT_DIR=$(pwd)
DOWNLOADS_DIR=${PROJECT_DIR}/downloads
NW_VERSION=${NW_VERSION:-"0.83.0"}
NW_BASENAME=${NW_BASENAME:-"nwjs"}
CHROMIUM_MAJOR_VERSION=120
CESIUM_DEFAULT_VERSION=1.7.15
NODE_VERSION=18

# Check first arguments = version
if [[ $1 =~ ^[0-9]+.[0-9]+.[0-9]+(-[a-z]+[-0-9]*)?$ ]];
then
  VERSION="$1"
  echo "Using Cesium version: $VERSION"
else
  if [[ -f ${PROJECT_DIR}/www/cesium/manifest.json ]];
  then
    VERSION=$(grep -m 1 -oP 'version": "\d+.\d+.\d+(-\w+[-0-9]*)?"' ${PROJECT_DIR}/www/cesium/manifest.json | grep -oP "\d+.\d+.\d+(-\w+[-0-9]*)?")
  fi

  if [[ $VERSION =~ ^[0-9]+.[0-9]+.[0-9]+(-[a-z]+[-0-9]*)?$ ]];
  then
    echo "Using Cesium detected version: $VERSION"
  else
    VERSION="${CESIUM_DEFAULT_VERSION}";
    echo "No Cesium version detected. Using default: $VERSION"
  fi
fi

# Force nodejs version to 10
if [[ -d "${NVM_DIR}" ]]; then
    . ${NVM_DIR}/nvm.sh
    nvm install ${NODE_VERSION}
else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit 1
fi

# Install NW.js
if [[ ! -f "${PROJECT_DIR}/www/nw" ]]; then
  echo "--- Installing NWJS ${NW_VERSION}..."
  mkdir -p "${DOWNLOADS_DIR}" && cd "${DOWNLOADS_DIR}" || exit 1
  cd "${DOWNLOADS_DIR}" || exit 1
  if [[ ! -f "${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz" ]]; then
    wget http://dl.nwjs.io/v${NW_VERSION}/${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz
    [[ $? -ne 0 ]] && exit 1
  fi

  # Uncompress archive
  tar xvf ${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz || exit 1

  # Copy to ./www
  mkdir -p "${PROJECT_DIR}/www"
  cp -rf ${NW_BASENAME}-v${NW_VERSION}-linux-x64/* "${PROJECT_DIR}/www" && rm -rf ${NW_BASENAME}-v${NW_VERSION}-linux-x64 || exit 1
  #rm ${NW_BASENAME}-v${NW_VERSION}-linux-x64.tar.gz || exit 1

# Check NW version
else
  cd "${PROJECT_DIR}/www" || exit 1
  NW_ACTUAL_VERSION=$(./nw --version | grep nwjs | awk '{print $2}')
  echo "Using Chromium version: ${NW_ACTUAL_VERSION}"
  CHROMIUM_ACTUAL_MAJOR_VERSION=$(echo "${NW_ACTUAL_VERSION}" | awk '{split($0, array, ".")} END{print array[1]}')
  if [[ ${CHROMIUM_ACTUAL_MAJOR_VERSION} -ne ${CHROMIUM_MAJOR_VERSION} ]]; then
    echo "Bad Chromium major version: ${CHROMIUM_ACTUAL_MAJOR_VERSION}. Expected version ${CHROMIUM_MAJOR_VERSION}."
    echo " - try to remove file '${PROJECT_DIR}/www/nw', then relaunch the script"
    cd "${PROJECT_DIR}"
    exit 1
  fi
fi


# Copy sources
echo "--- Copying sources from ./src to ./www"
cd "${PROJECT_DIR}/www/" || exit 1
cp -rf ${PROJECT_DIR}/src/* .
cp -f ${PROJECT_DIR}/LICENSE LICENSE.txt

# Install dependencies
echo "--- Install dependencies to ./www/node_modules"
npm install

# Remove old Cesium version
if [[ -f ${PROJECT_DIR}/www/cesium/index.html ]];
then
  OLD_VERSION=$(grep -oP "version\": \"\d+.\d+.\d+(\w+[-0-9]*)?\"" ${PROJECT_DIR}/www/cesium/manifest.json | grep -oP "\d+.\d+.\d+(\w+[-0-9]*)?")
  if [[ ! "$VERSION" = "$OLD_VERSION" ]];
  then
    echo "--- Removing old Cesium v${OLD_VERSION}..."
    rm -rf ${PROJECT_DIR}/www/cesium
  fi
fi

# Install Cesium web
if [[ ! -f ${PROJECT_DIR}/www/cesium/index.html ]]; then
    echo "--- Downloading Cesium v${VERSION}..."

    mkdir -p "${DOWNLOADS_DIR}" && cd "${DOWNLOADS_DIR}" || exit 1
    if [[ ! -f "${cesium-v${VERSION}-web.zip}" ]]; then
      wget "https://github.com/duniter/cesium/releases/download/v${VERSION}/cesium-v${VERSION}-web.zip"
      if [[ $? -ne 0 ]]; then
          echo "Could not download Cesium web release !"
          exit 1;
      fi
    fi
    mkdir -p "${PROJECT_DIR}/www/cesium" || exit 1
    unzip -o "cesium-v${VERSION}-web.zip" -d "${PROJECT_DIR}/www/cesium" || exit 1

  # Add cesium-desktop.js file into HTML files
  cd "${PROJECT_DIR}/www/cesium" || exit 1
  sed -i 's/<script src="config.js"[^>]*><\/script>/<script src="config.js"><\/script>\n\t<script src="..\/cesium-desktop.js"><\/script>/g' index*.html || exit 1

fi


cd ${PROJECT_DIR} || exit 1
