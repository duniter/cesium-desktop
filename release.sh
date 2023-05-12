#!/bin/bash

PROJECT_NAME=cesium
REPO="duniter/cesium"
REPO_PUBLIC_URL="https://github.com/${REPO}"
NODEJS_VERSION=10
TAG="$1"
TAG_NAME="v$1"
ARCH=`uname -m`

# Folders
ROOT=`pwd`
DOWNLOADS="$ROOT/downloads"

mkdir -p "$DOWNLOADS"

# Check that the tag exists remotely

if [[ -z $TAG ]]; then
  echo "Wrong call to the command, syntax is:"
  echo ""
  echo "  release.sh <tag>"
  echo ""
  echo "Examples:"
  echo ""
  echo "  release.sh 1.2.3"
  echo "  release.sh 1.4.0"
  echo "  release.sh 1.4.1"
  echo ""
  exit 1
fi

# Override with a local file, if any
if [[ -f "${ROOT}/.local/env.sh" ]]; then
  echo "Loading environment variables from: '.local/env.sh'"
  source ${ROOT}/.local/env.sh
  [[ $? -ne 0 ]] && exit 1
else
  echo "No file '${ROOT}/.local/env.sh' found. Will use defaults"
fi

# Force nodejs version
if [[ -d "${NVM_DIR}" ]]; then
    . ${NVM_DIR}/nvm.sh
    nvm use ${NODEJS_VERSION}
    if [[ $? -ne 0 ]]; then
        nvm install ${NODEJS_VERSION}
        if [[ $? -ne 0 ]]; then
            exit 1;
        fi
    fi

else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit 1
fi

# install dep if not already done
if [[ ! -d "node_modules" ]]; then
    yarn
fi

# Check that the tag exists remotely
echo "Checking that $TAG has been pushed to 'origin'..."
REMOTE_TAG=`node scripts/exists-tag.js "$TAG_NAME" | grep -Fo "$TAG_NAME"`

if [[ -z ${REMOTE_TAG} ]]; then
  echo "The '$TAG' tag does not exist on 'origin' repository. Use command ./release.sh to create a new version and use 'git push origin --tags' to share the tag."
  exit 2
fi

echo "Remote tag: $REMOTE_TAG"
echo "Creating the pre-release if it does not exist..."
ASSETS=`node ./scripts/create-release.js $REMOTE_TAG create`

# Downloading web assets (once)
ZIP_BASENAME="${PROJECT_NAME}-${REMOTE_TAG}-web"
if [[ ! -f "${DOWNLOADS}/${ZIP_BASENAME}.zip" ]]; then
    echo "Downloading ${PROJECT_NAME} web release..."
    mkdir -p ${DOWNLOADS} && cd ${DOWNLOADS} || exit 1
    wget "${REPO_PUBLIC_URL}/releases/download/${REMOTE_TAG}/${ZIP_BASENAME}.zip"
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    cd ${ROOT}
fi

if [[ "_$EXPECTED_ASSETS" == "_" ]]; then
    EXPECTED_ASSETS="${PROJECT_NAME}-desktop-$REMOTE_TAG-linux-x64.deb
${PROJECT_NAME}-desktop-$REMOTE_TAG-linux-x64.tar.gz
${PROJECT_NAME}-desktop-$REMOTE_TAG-windows-x64.exe"
fi

# Remove old vagrant virtual machines
echo "Removing old Vagrant VM... TODO: optimize this !"
rm -rf ~/.vagrant.d/*

#echo "Assets: $EXPECTED_ASSETS"

for ASSET_BASENAME in $EXPECTED_ASSETS; do

  echo ""
  echo "--- Checking if asset '$ASSET_BASENAME' exists on GitHub..."
  if [[ -z `echo $ASSETS | grep -F "$ASSET_BASENAME"` ]]; then

    # Debian
    if [[ $ASSET_BASENAME == *"linux-x64.deb" ]] || [[ $ASSET_BASENAME == *"linux-x64.tar.gz" ]]; then
      if [[ $ARCH == "x86_64" ]]; then

        ASSET_PATH="$PWD/arch/linux/$ASSET_BASENAME"

        # Build
        if [[ ! -f "${ASSET_PATH}" ]]; then
          echo "--- Building '${ASSET_BASENAME}'..."
          ./scripts/build.sh make linux $TAG
          [[ $? -eq 0 ]] && echo "--- Building '${ASSET_BASENAME}' [OK]"
        fi

        # Upload asset
        if [[ -f "${ASSET_PATH}" ]]; then
          echo ""
          echo "--- Uploading '${ASSET_BASENAME}' to github ..."
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}
        fi

        # Upload sha256 (if exists)
        if [[ -f "${ASSET_PATH}.sha256" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}.sha256
        fi
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi

    # Windows
    if [[ $ASSET_BASENAME == *".exe" ]]; then
      if [[ $ARCH == "x86_64" ]]; then

        ASSET_PATH="$PWD/arch/windows/$ASSET_BASENAME"

        # Build
        if [[ ! -f "${ASSET_PATH}" ]]; then
          echo "--- Building '${ASSET_BASENAME}'..."
          ./scripts/build.sh make win $TAG
          [[ $? -eq 0 ]] && echo "--- Building '${ASSET_BASENAME}' [OK]"
        fi

        # Upload asset
        if [[ -f "${ASSET_PATH}" ]]; then
          echo ""
          echo "--- Uploading '${ASSET_BASENAME}' to github ..."
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}
        fi

        # Upload sha256 (if exists)
        if [[ -f "${ASSET_PATH}.sha256" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}.sha256
        fi
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi

    # OSX
    if [[ $ASSET_BASENAME == *"osx-x64.zip" ]]; then
      if [[ $ARCH == "x86_64" ]]; then
        ASSET_PATH="$PWD/arch/osx/$ASSET_BASENAME"

        # Build
        if [[ ! -f "${ASSET_PATH}" ]]; then
          echo "--- Building '${ASSET_BASENAME}'..."
          ./scripts/build.sh make osx $TAG
          [[ $? -eq 0 ]] && echo "--- Building '${ASSET_BASENAME}' [OK]"
        fi

        # Upload asset
        if [[ -f "${ASSET_PATH}" ]]; then
          echo ""
          echo "--- Uploading '${ASSET_BASENAME}' to github ..."
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}
        fi

        # Upload sha256 (if exists)
        if [[ -f "${ASSET_PATH}.sha256" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${ASSET_PATH}.sha256
        fi
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi
  fi
done

if [[ $? -eq 0 ]]; then
  cd ${ROOT}

  # Clean temporary files
  if [[ $? -eq 0 ]]; then
    rm downloads/cesium-*-web.zip
    rmdir --ignore-fail-on-non-empty downloads

    echo "--- All assets have been uploaded."
  fi

fi
