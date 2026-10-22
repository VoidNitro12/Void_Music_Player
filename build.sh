#!/bin/bash

set -e

OS=$(uname -s)
PLATFORM=""
PROJECT_ROOT=$(pwd)

if [ "$OS" = "Linux" ]; then
    PLATFORM="linux"
elif [[ "$OS" == *"MINGW"* ]] || [[ "$OS" == *"MSYS"* ]]; then
    PLATFORM="windows"
fi

echo "Building for: $PLATFORM"

# Build Taglib
echo "Building TagLib..."

TAGLIB_FOLDER="MusicPlayerGDextension/third_party/taglib-2.3.2"

cd $TAGLIB_FOLDER/taglib-src

if [ "$PLATFORM" = "windows" ]; then
    cmake -S . \
    -B $TAGLIB_FOLDER/builds/build-$PLATFORM \
    -DCMAKE_INSTALL_PREFIX="$PROJECT_ROOT/$TAGLIB_FOLDER/install/windows" \
    -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/$TAGLIB_FOLDER/mingw64.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_BINDINGS=OFF \
    -DWITH_ZLIB=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
elif [ "$PLATFORM" = "linux" ]; then
    cmake -S . \
    -B $TAGLIB_FOLDER/builds/build-$PLATFORM \
    -DCMAKE_INSTALL_PREFIX="$PROJECT_ROOT/$TAGLIB_FOLDER/install/linux" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_BINDINGS=OFF \
    -DWITH_ZLIB=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
fi

cmake --build $TAGLIB_FOLDER/builds/build-$PLATFORM
cmake --install $TAGLIB_FOLDER/builds/build-$PLATFORM

echo "Building GDExtension"
cd $PROJECT_ROOT/MusicPlayerGDextension
if [ "$PLATFORM" = "windows" ]; then
    scons platform=windows target=template_debug use_mingw=yes -j2 
elif [ "$PLATFORM" = "linux" ]; then
    scons platform=linux target=template_debug -j2
fi