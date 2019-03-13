#!/bin/bash

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

# Force nodejs version to 6
if [[ -d "$NVM_DIR" ]]; then
    . $NVM_DIR/nvm.sh
    nvm use 6
else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit -1
fi

# install dep if not already done
if [[ ! -d "node_modules" ]]; then
    npm install
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
fi

echo "Checking that $TAG has been pushed to 'origin'..."
REMOTE_TAG=`node scripts/exists-tag.js "$TAG_NAME" | grep -Fo "$TAG_NAME"`
if [[ -z $REMOTE_TAG ]]; then
  echo "The '$TAG' tag does not exist on 'origin' repository. Use command ./new_version.sh to create a new version and use 'git push origin --tags' to share the tag."
  exit 2
fi

echo "Remote tag: $REMOTE_TAG"
echo "Creating the pre-release if it does not exist..."
ASSETS=`node ./scripts/create-release.js $REMOTE_TAG create`

# Downloading web assets (once)
CESIUM_RELEASE="cesium-$REMOTE_TAG-web"
if [[ ! -f "${DOWNLOADS}/${CESIUM_RELEASE}.zip" ]]; then
    echo "Downloading Cesium web release..."
    mkdir -p ${DOWNLOADS} && cd ${DOWNLOADS}
    wget "https://github.com/duniter/cesium/releases/download/$REMOTE_TAG/$CESIUM_RELEASE.zip"
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    cd $ROOT
fi


if [[ "_$EXPECTED_ASSETS" == "_" ]]; then
  EXPECTED_ASSETS="cesium-desktop-$REMOTE_TAG-linux-x64.deb
cesium-desktop-$REMOTE_TAG-linux-x64.tar.gz
cesium-desktop-$REMOTE_TAG-windows-x64.exe"
fi


# Remove old vagrant virtual machines
#echo 'Removing old Vagrant VM... TODO: optimize this !'
#rm -rf ~/.vagrant.d/*

for asset in $EXPECTED_ASSETS; do
  if [[ -z `echo $ASSETS | grep -F "$asset"` ]]; then

    echo "Missing asset: $asset"

    # Debian
    if [[ $asset == *"linux-x64.deb" ]] || [[ $asset == *"linux-x64.tar.gz" ]]; then
      if [[ $ARCH == "x86_64" ]]; then
        echo "Starting Debian build..."
        ./scripts/build.sh make linux $TAG
        DEB_PATH="$PWD/arch/linux/$asset"
        if [[ $? -eq 0 ]] && [[ -f "${DEB_PATH}" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${DEB_PATH}
        fi
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi

    # Windows
    if [[ $asset == *".exe" ]]; then
      if [[ $ARCH == "x86_64" ]]; then
        echo "Starting Windows build..."
        ./scripts/build.sh make win $TAG
        WIN_PATH="$PWD/arch/windows/$asset"
        if [[ -f "${WIN_PATH}" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${WIN_PATH}
        fi
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi

    # OSX
    if [[ $asset == *"osx.zip" ]]; then
      if [[ $ARCH == "x86_64" ]]; then
        echo "Starting OSX build..."
        ./scripts/build.sh make osx $TAG
        OSX_PATH="$PWD/arch/osx/$asset"
        if [[ -f "${OSX_PATH}" ]]; then
          node ./scripts/upload-release.js ${REMOTE_TAG} ${OSX_PATH}
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
    rm ${DOWNLOADS}/cesium-*-web.zip
    rmdir downloads

    echo "All the binaries have been uploaded."
  fi

fi
