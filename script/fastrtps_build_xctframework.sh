#!/bin/bash
#
# fastrtps_build_xctframework.sh
# Copyright © 2020 Dmitriy Borovikov. All rights reserved.
#
set -e
set -x

if [[ $# > 0 ]]; then
TAG=$1
else
echo "Usage: fastrtps_build_xctframework.sh TAG commit"
echo "where TAG is FasT-DDS version tag eg. 2.0.1"
exit -1
fi

BRANCH=$(git branch --show-current)
if [ "$BRANCH" == "master" ]
then
    FastRTPS_repo="-b v$TAG https://github.com/eProsima/Fast-DDS.git"
    ReleaseNote="Fast-DDS $TAG: iOS(armv7, armv7s, arm64), iOS Simulator(x86_64, arm64), macOS(x86_64, arm64), maccatalyst (x86_64, arm64)."
elif [ "$BRANCH" == "whitelist" ]
then
    FastRTPS_repo="-b feature/remote-whitelist-$TAG https://github.com/DimaRU/Fast-DDS.git"
    ReleaseNote="Fast-DDS $TAG: iOS(armv7, armv7s, arm64), iOS Simulator(x86_64, arm64), macOS(x86_64, arm64), maccatalyst (x86_64, arm64). Remote whitelist feature."
    TAG="$TAG-$BRANCH"
else
    echo "Wrong branch $BRANCH"
    exit -1
fi
echo $TAG

ZIPNAME=fastrtps-$TAG.xcframework.zip
GIT_REMOTE_URL_UNFINISHED=`git config --get remote.origin.url|sed "s=^ssh://==; s=^https://==; s=:=/=; s/git@//; s/.git$//;"`
DOWNLOAD_URL=https://$GIT_REMOTE_URL_UNFINISHED/releases/download/$TAG/$ZIPNAME

export ROOT_PATH=$(cd "$(dirname "$0")/.."; pwd -P)
pushd $ROOT_PATH > /dev/null

BUILD=$ROOT_PATH/build
export PROJECT_TEMP_DIR=$BUILD/temp
export SOURCE_DIR=$BUILD/src

if [ ! -d $SOURCE_DIR/memory ]; then
git clone --quiet https://github.com/foonathan/memory.git $SOURCE_DIR/memory
pushd $SOURCE_DIR/memory > /dev/null
git checkout 7851d12
popd > /dev/null
fi
if [ ! -d $SOURCE_DIR/Fast-DDS ]; then
git clone --quiet --recurse-submodules --depth 1 $FastRTPS_repo $SOURCE_DIR/Fast-DDS
fi

source script/fastrtps_build_apple.sh

# BUILT_PRODUCTS_DIR=$BUILD/macosx
# PLATFORM_NAME=macosx
# EFFECTIVE_PLATFORM_NAME=""
# ARCHS="x86_64 arm64"
#buildLibrary "$BUILD/macosx" "macosx" "" "arm64"
buildLibrary "$BUILD/iphoneos" "iphoneos" "" "arm64"
#buildLibrary "$BUILD/iphonesimulator" "iphonesimulator" "-iphonesimulator" "x86_64 arm64"

CHECKSUM=`shasum -a 256 -b $ZIPNAME | awk '{print $1}'`

cat >Package.swift << EOL
// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FastDDS",
    products: [
        .library(name: "FastDDS", targets: ["FastDDS"])
    ],
    targets: [
        .binaryTarget(name: "FastDDS",
                      url: "$DOWNLOAD_URL",
                      checksum: "$CHECKSUM")
    ]
)
EOL

if [[ $2 == "commit" ]]; then

git add Package.swift
git commit -m "Build $TAG"
git tag $TAG
git push
git push --tags
gh release create "$TAG" $ZIPNAME --title "$TAG" --notes "$ReleaseNote"

fi
popd > /dev/null
