#!/bin/bash

TAG="$1"
TAG_NAME="v$1"
ARCH=`uname -m`
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
if [ -d "$NVM_DIR" ]; then
    . $NVM_DIR/nvm.sh
    nvm use 6
else
    echo "nvm (Node version manager) not found (directory NVM_DIR not defined). Please install nvm, and retry"
    exit -1
fi

# install dep if not already done
if [ ! -d "node_modules" ]; then
    npm install
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


if [[ "_$EXPECTED_ASSETS" == "_" ]]; then
  EXPECTED_ASSETS="cesium-desktop-$REMOTE_TAG-linux-x64.deb
cesium-desktop-$REMOTE_TAG-linux-x64.tar.gz
cesium-desktop-$REMOTE_TAG-windows-x64.exe"
fi

for asset in $EXPECTED_ASSETS; do
  if [[ -z `echo $ASSETS | grep -F "$asset"` ]]; then

    echo "Missing asset: $asset"

    # Debian
    if [[ $asset == *"linux-x64.deb" ]] || [[ $asset == *"linux-x64.tar.gz" ]]; then
      if [[ $ARCH == "x86_64" ]]; then
        echo "Starting Debian build..."
        ./scripts/build.sh make linux $TAG
        DEB_PATH="$PWD/arch/linux/$asset"
        node ./scripts/upload-release.js $REMOTE_TAG $DEB_PATH
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
        node ./scripts/upload-release.js $REMOTE_TAG $WIN_PATH
      else
        echo "This computer cannot build this asset, required architecture is 'x86_64'. Skipping."
      fi
    fi
  fi
done

echo "All the binaries have been uploaded."
