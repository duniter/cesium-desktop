#!/bin/bash

VERSION=1.3.11

EXPECTED_ASSETS="cesium-desktop-v${VERSION}-osx-x64.zip"
export EXPECTED_ASSETS

cd ../

./release.sh $VERSION



