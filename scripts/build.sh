#!/bin/bash
set -euo pipefail

# Config
OS=$(uname -s)
PLATFORM=""
PROJECT_FILE="project.godot"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )" # its in a folder

# Helpers
die() {
    echo "error: $*" >&2
    exit 1
}

info() { echo "==> $*"; }

cd "$PROJECT_ROOT"

# If project.godot isnt found the script probably as been moved without updating this one
[[ -f "$PROJECT_FILE" ]] || die "$PROJECT_FILE not found — is the script in scripts/?"

case $OS in
    Linux) PLATFORM="linux" ;;
    *MINGW*|*MSYS*) PLATFORM="windows" ;;
    *) die "Unsupported OS: $OS";;
esac


TARGET=""
ARG="${1:-}"

case "$ARG" in
    template_release) TARGET="template_release" ;;
    template_debug)   TARGET="template_debug" ;;
    "")  info "No target specified, defaulting to template_debug" >&2
         TARGET="template_debug" ;;
    *)   info "Unknown target: $ARG, defaulting to template_debug" >&2
         TARGET="template_debug" ;;
esac

info "Building for: $PLATFORM"
echo 
# Build Taglib
info "Building TagLib..."
echo

TAGLIB_FOLDER="MusicPlayerGDextension/third_party/taglib-2.3.2"
TAG_SRC="$PROJECT_ROOT/$TAGLIB_FOLDER/taglib-src"
BUILD_DIR="$PROJECT_ROOT/$TAGLIB_FOLDER/builds/build-$PLATFORM"
INSTALL_DIR="$PROJECT_ROOT/$TAGLIB_FOLDER/install/$PLATFORM"

# Ensure the taglib src exists 
[ -d "$TAG_SRC" ] || { die "Missing TagLib source: $TAG_SRC"; }

CMAKE_OPTS=(
    -S "$TAG_SRC" -B "$BUILD_DIR"
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_BINDINGS=OFF
    -DWITH_ZLIB=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

if [ "$PLATFORM" = "windows" ]; then
    CMAKE_OPTS+=(-DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/$TAGLIB_FOLDER/mingw64.cmake")
fi

cmake "${CMAKE_OPTS[@]}"
cmake --build "$BUILD_DIR"
cmake --install "$BUILD_DIR"

echo 
info "Built Taglib"
echo 

info "Building FFmpeg"
FFMPEG_FOLDER="MusicPlayerGDextension/third_party/ffmpeg-9.0"
FFMPEG_SRC="$PROJECT_ROOT/$FFMPEG_FOLDER/ffmpeg-src"
FFMPEG_INSTALL_DIR="$PROJECT_ROOT/$FFMPEG_FOLDER/install/$PLATFORM"

# Ensure the ffmpeg src exists 
[ -d "$FFMPEG_SRC" ] || die "Missing FFmpeg source: $FFMPEG_SRC"

cd "$FFMPEG_SRC"

./configure \
  --prefix="$FFMPEG_INSTALL_DIR" \
  --disable-gpl --disable-nonfree --disable-version3 \
  --disable-autodetect \
  --disable-static --enable-shared \
  --disable-programs --disable-doc --disable-debug \
  --disable-everything \
  --enable-avformat --enable-avcodec --enable-avutil --enable-swresample \
  --enable-demuxer=mov \
  --enable-decoder=aac,alac \
  --enable-parser=aac \
  --enable-protocol=file

make -j"$(nproc 2>/dev/null || echo 2)"
make install 

export PKG_CONFIG_PATH="$FFMPEG_INSTALL_DIR/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

echo 
info "Built FFmpeg"
echo 

info "Building GDExtension"
info "Building $TARGET"
echo 

cd "$PROJECT_ROOT/MusicPlayerGDextension"

if [ "$PLATFORM" = "windows" ]; then
    scons platform=windows target=$TARGET use_mingw=yes -j"$(nproc 2>/dev/null || echo 2)"
elif [ "$PLATFORM" = "linux" ]; then
    scons platform=linux target=$TARGET -j"$(nproc 2>/dev/null || echo 2)"
fi
echo 
info "Finished Building"