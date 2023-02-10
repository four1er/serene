#! /bin/bash
# Serene Programming Language
#
# Copyright (c) 2019-2023 Sameer Rahmani <lxsameer@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -----------------------------------------------------------------------------
# Commentary
# -----------------------------------------------------------------------------
# This is the builder script for the Serene project. It makes it easier to
# interact with the CMake build scripts.
#
# In order to define a subcommand all you need to do is to define a function
# with the following syntax:
#
# function subcommand-name() { ## DESCRIPTION
#   .. subcommand body ..
# }
#
# Make sure to provid one line of DESCRIPTION for the subcommand and use two "#"
# characters to start the description following by a space. Otherwise, your
# subcommand won't be registered
#
## Verbos Mode
# In order to turn on the verbose mode for your build just invoke the builder script
# like:
#
# $ VERBOSE=ON ./builder build/
#
set -e

command=$1
VERSION="0.8.0"

ME=$(cd "$(dirname "$0")/." >/dev/null 2>&1 ; pwd -P)

# shellcheck source=./scripts/utils.sh
source "$ME/scripts/utils.sh"

# shellcheck source=./scripts/devfs.sh
source "$ME/scripts/devfs.sh"

# -----------------------------------------------------------------------------
# CONFIG VARS
# -----------------------------------------------------------------------------

# By default Clang is the compiler that we use and support. But you may use
# whatever you want. But just be aware of the fact that we might not be able
# to help you in case of any issue.
if [[ "$CC" = "" ]]; then
    CC=$(which clang || echo "Clang_not_found")
    export CC
fi
if [[ "$CXX" = "" ]]; then
    CXX=$(which clang++ || echo "Clang++_not_found")
    export CXX
fi

# Using LLD is a must
LDFLAGS="-fuse-ld=lld"

# The target architectures that we want to build Serene in and also we want
# serene to support. We use this variable when we're building the llvm
TARGET_ARCHS="X86;AArch64;AMDGPU;ARM;RISCV;WebAssembly"

# The repository to push/pull packages to/from.
DEV_HEROES="https://beta.devheroes.codes"

BUILD_DIR_NAME="build"
export BUILD_DIR_NAME

BUILD_DIR="$ME/$BUILD_DIR_NAME"
export BUILD_DIR

DEPS_BUILD_DIR="$HOME/.serene/env"
export DEPS_BUILD_DIR

# Serene subprojects. We use this array to run common tasks on all the projects
# like running the test cases
PROJECTS=(libserene serenec serene-repl serene-tblgen)

# TODO: Remove this
LLVM_VERSION="11"

# TODO: Add sloppiness to the cmake list file as well
CCACHE_SLOPPINESS="pch_defines,time_macros"
export CCACHE_SLOPPINESS

ASAN_OPTIONS=check_initialization_order=1
export ASAN_OPTIONS

LSAN_OPTIONS=suppressions="$ME/.ignore_sanitize"
export LSAN_OPTIONS

# shellcheck source=./scripts/deps.sh
source "$ME/scripts/deps.sh"


CMAKEARGS_DEBUG=(
    "-DCMAKE_BUILD_TYPE=Debug"
)

CMAKEARGS=(
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    "-DSERENE_USE_LIBCXX=ON"
    "-DSERENE_TOOLCHAIN_PATH=$LLVM_INSTALL_DIR"
    "-DSERENE_CCACHE_DIR=$HOME/.ccache"
)


# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
mkdir -p "$DEPS_BUILD_DIR"


# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

function gen_precompile_header_index() {
     {
        echo "// DO NOT EDIT THIS FILE: It is aute generated by './builder gen_precompile_index'"
        echo "#ifndef SERENE_PRECOMPIL_H"
        echo "#define SERENE_PRECOMPIL_H"
        grep -oP  "#include .llvm/.*" . -R|cut -d':' -f2|tail +2
        grep -oP  "#include .mlir/.*" . -R|cut -d':' -f2|tail +2
        echo "#endif"
    } > ./include/serene_precompiles.h
}


function pushed_build() {
    mkdir -p "$BUILD_DIR"
    pushd "$BUILD_DIR" > /dev/null || return
}


function popd_build() {
    popd > /dev/null || return
}


function build-gen() {
    pushed_build
    info "Running: "
    info "cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=$ME/cmake/toolchains/linux.cmake" "$ME" "${CMAKEARGS[*]} ${CMAKEARGS_DEBUG[*]}" "$@"
    cmake -G Ninja "-DCMAKE_TOOLCHAIN_FILE=$ME/cmake/toolchains/linux.cmake" "$ME" "${CMAKEARGS[@]}" "${CMAKEARGS_DEBUG[@]}" "$@"
    popd_build
}

# -----------------------------------------------------------------------------
# Subcomaands
# -----------------------------------------------------------------------------

function deps() { ## Manage the dependencies
    manage_dependencies "$@"
}

function compile() { ## Compiles the project using the generated build scripts
    pushed_build
    cmake --build . --parallel
    popd_build
}

function build() { ## Builds the project by regenerating the build scripts
    local cpus

    rm -rf "$BUILD_DIR"
    build-gen "$@"
    pushed_build

    cpus=$(nproc)
    cmake --build . -j "$cpus"
    popd_build
}

function build-20() { ## Builds the project using C++20 (will regenerate the build)
    rm -rf "$BUILD_DIR"
    pushed_build
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCPP_20_SUPPORT=ON "$@" "$ROOT_DIR"
    cmake --build .
    popd_build
}

function build-tidy() { ## Builds the project using clang-tidy (It takes longer than usual)
    build "-DSERENE_ENABLE_TIDY=ON" "${@:2}"
}

function build-release() { ## Builds the project in "Release" mode
    rm -rf "$BUILD_DIR"
    pushed_build
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release "${CMAKEARGS[@]}" "$ROOT_DIR"
    cmake --build . --config Release
    popd_build
}

function build-docs() { ## Builds the documentation of Serene
    rm -rf "$BUILD_DIR"
    pip install -r "$ME/docs/requirements.txt"
    pushed_build
    cmake -G Ninja -DSERENE_ENABLE_DOCS=ON "$ROOT_DIR"
    cmake --build .
    popd_build
}

function serve-docs() { ## Serve the docs directory from build dir
    python -m http.server --directory "$BUILD_DIR/docs/sphinx/"
}

function clean() { ## Cleans up the source dir and removes the build
    git clean -dxf
}

function run() { ## Runs `serenec` and passes all the given aruguments to it
    "$BUILD_DIR"/serenec/serenec "$@"
}

function lldb-run() { ## Runs `serenec` under lldb
    lldb -- "$BUILD_DIR"/serenec/serenec "$@"
}

function repl() { ## Runs `serene-repl` and passes all the given aruguments to it
    "$BUILD_DIR"/serene-repl/serene-repl "$@"
}

function memcheck-serene() { ## Runs `valgrind` to check `serenec` birany
    export ASAN_FLAG=""
    build
    pushed_build
    valgrind --tool=memcheck --leak-check=yes --trace-children=yes "$BUILD_DIR"/bin/serenec "$@"
    popd_build
}

function tests() { ## Runs all the test cases
    if [[ "$1" == "all" || "$1" == "" ]]; then
        info "Run the entire test suit"
        for proj in "${PROJECTS[@]}"; do
            local test_file="$BUILD_DIR/$proj/tests/${proj}Tests"

            if [[ -f "$test_file" ]]; then
                eval "$test_file ${*:2}"
            fi
        done
    else
        eval "$BUILD_DIR/$1/tests/$1Tests ${*:2}"
    fi
}

function build-tests() { ## Generates and build the project including the test cases
    rm -rf "$BUILD_DIR"
    pushed_build
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DSERENE_BUILD_TESTING=ON "$ROOT_DIR"
    cmake --build .
    popd_build
}

function build-llvm-image() { ## Build thh LLVM images of Serene for all platforms
    # shellcheck source=/dev/null
    source .env
    if [ "$1" ]; then
        cleanup_builder || setup_builder
        podman login "$REGISTRY" -u "$SERENE_REGISTERY_USER" -p "$SERENE_REGISTERY_PASS"
        build_llvm "$1" "$ME"
        build_ci "$1" "$ME"
        cleanup_builder
    else
        error "Pass the llvm version as input"
    fi
}

function push-images() { ## Pushes all the related image to the registery
    # shellcheck source=/dev/null
    source .env
    if [ "$1" ]; then
        push_images "$1" "$ME"
    else
        error "Pass the llvm version as input"
    fi
}

function build-serene-image-arm64() { ## Build the Serene docker image for the current HEAD (on ARM64)
    # shellcheck source=/dev/null
    source .env

    docker buildx build --platform linux/arm64 --builder multiarch --load \
           -f "$ME/resources/docker/serene/Dockerfile" \
           -t "$REGISTRY/serene:$VERSION-$(git rev-parse HEAD)" \
           .
}


function build-serene-image() { ## Build the Serene docker image for the current HEAD
    # shellcheck source=/dev/null
    source .env

    docker build \
           -f "$ME/resources/docker/serene/Dockerfile" \
           -t "$REGISTRY/serene:$VERSION-$(git rev-parse HEAD)" \
           .
}

function release-serene-image() { ## Build and push the Serene docker image for the current HEAD in Release mode
    # shellcheck source=/dev/null
    source .env
    docker build \
           -f "$ME/resources/docker/serene/Dockerfile" \
           -t "$REGISTRY/serene:$VERSION" \
           --build-arg TASK=build-release \
           .
    docker login "$REGISTRY" -u "$SERENE_REGISTERY_USER" -p "$SERENE_REGISTERY_PASS"
    docker push "$REGISTRY/serene:$VERSION"
}

function create-devfs-image() { ## Create the devfs images locally (requires sudo)
    # shellcheck source=/dev/null
    source .env

    local output_dir

    output_dir="$DEV_FS_DIR/image"
    mkdir -p "$output_dir"

    create_and_initialize_devfs_image "$output_dir" "$ME" "$LLVM_VERSION"
}

function setup() { ## Setup the working directory and make it ready for development
    if command -v python3 >/dev/null 2>&1; then
        pip install pre-commit
        pre-commit install
    else
        error "Python is required to setup pre-commit"
    fi
}

function setup-dev() { ## Setup the container like env to build/develop Serene (requires sudo access)
    # shellcheck source=/dev/null
    source .env

    local fs_tarball
    local rootfs

    fs_tarball="$DEV_FS_DIR/fs.tar.xz"
    rootfs="$DEV_FS_DIR/fs"

    mkdir -p "$DEV_FS_DIR"

    if [[ -f "$rootfs/etc/shadow" ]]; then
       info "RootFS already exits. Skipping..."
    else
        info "RootFS is missing."
        if [ ! -f "$fs_tarball" ]; then
            download_devfs "$SERENE_FS_REPO" "$fs_tarball"
        else
            info "FS tarball exists at '$fs_tarball'"
        fi

        extract_devfs "$fs_tarball" "$rootfs"
    fi

    init_devfs "$rootfs" "$ME"

    info "The 'devfs' setup is finished!"
    echo
    echo "===================================================================="
    echo "DO NOT MANUALLY REMOVE THE DIRECTORY!!!"
    echo "Instead use the builder command 'destroy-devfs' ro remove it"
    echo "===================================================================="
}

function push_devfs_imagse() { ## Push the created devfs image to the "registry" (air quote)
    # shellcheck source=/dev/null
    source .env

    local image_dir

    image_dir="$DEV_FS_DIR/image"

    sync_devfs_image "$image_dir"
    mark_devfs_image_as_latest "$image_dir"
}

function destroy-devfs() { ## Destroy the 'devfs' by unmounting the volumes and deleting the files
    # shellcheck source=/dev/null
    source .env

    local rootfs
    rootfs="$DEV_FS_DIR/fs"

    yes_or_no "Do you really want to remove the 'devfs'?" && \
        unmount_and_destroy_devfs "$rootfs"
}

function build-in-devfs() { ## Destroy the 'devfs' by unmounting the volumes and deleting the files
    # shellcheck source=/dev/null
    source .env

    local rootfs
    rootfs="$DEV_FS_DIR/fs"

    rootless "$rootfs" ./builder build
}

function devfs_root_shell() { ## Get a bash shell as root on the devfs
    # shellcheck source=/dev/null
    source .env

    local rootfs

    rootfs="$DEV_FS_DIR/fs"

    if [[ -f "$rootfs/etc/shadow" ]]; then
        as_root "$rootfs" bash
    else
        error "DevFS does not exist run './builder setup-dev' first"
    fi
}

function devfs_shell() { ## Get a bash shell on the devfs
    # shellcheck source=/dev/null
    source .env

    local rootfs

    rootfs="$DEV_FS_DIR/fs"

    if [[ -f "$rootfs/etc/shadow" ]]; then
        rootless "$rootfs" bash
    else
        error "DevFS does not exist run './builder setup-dev' first"
    fi
}

function scan-build() { ## Runs the `scan-build` utility to analyze the build process
    rm -rf "$BUILD_DIR"
         build-gen
         pushed_build
         # The scan-build utility scans the build for bugs checkout the man page
         scan-build --force-analyze-debug-code --use-analyzer="$CC" cmake --build .
         popd_build
}

function help() { ## Print out this help message
    echo "Commands:"
    grep -E '^function [a-zA-Z0-9_-]+\(\) \{ ## .*$$' "$0" | \
        sort | \
        sed 's/^function \([a-zA-Z0-9_-]*\)() { ## \(.*\)/\1:\2/' | \
        awk 'BEGIN {FS=":"}; {printf "\033[36m%-30s\033[0m %s\n", $1, $2}'
}

# -----------------------------------------------------------------------------
# Main logic
# -----------------------------------------------------------------------------
echo -e "\nSerene  Builder Version $VERSION"
echo -e "\nCopyright (C) 2019-2023"
echo -e "Sameer Rahmani <lxsameer@gnu.org>"
echo -e "Serene comes with ABSOLUTELY NO WARRANTY;"
echo -e "This is free software, and you are welcome"
echo -e "to redistribute it under certain conditions;"
echo -e "for details take a look at the LICENSE file.\n"

# Find the subcommand in the functions and run we find it.
for fn in $(fn-names); do
    if [[ $fn == "$command" ]]; then
        eval "$fn ${*:2}"
        exit $?
    fi
done

# If we couldn't find the command print out the help message
help
