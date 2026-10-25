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

echo "Building for: $PLATFORM"

# Build Taglib
echo "Building TagLib..."

TAGLIB_FOLDER="MusicPlayerGDextension/third_party/taglib-2.3.2"
TAG_SRC="$PROJECT_ROOT/$TAGLIB_FOLDER/taglib-src"
BUILD_DIR="$PROJECT_ROOT/$TAGLIB_FOLDER/builds/build-$PLATFORM"
INSTALL_DIR="$PROJECT_ROOT/$TAGLIB_FOLDER/install/$PLATFORM"

# Ensure the taglib src exists and exit with an error if not
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

info "Building GDExtension"
info "Building $TARGET"

cd "$PROJECT_ROOT/MusicPlayerGDextension"

if [ "$PLATFORM" = "windows" ]; then
    scons platform=windows target=$TARGET use_mingw=yes -j2 
elif [ "$PLATFORM" = "linux" ]; then
    scons platform=linux target=$TARGET -j2
fi