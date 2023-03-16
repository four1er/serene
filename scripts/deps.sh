#! /bin/bash
# Serene Programming Language
#
# Copyright (c) 2019-2022 Sameer Rahmani <lxsameer@gnu.org>
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
# This file contains some functions to build, pack and distribute the
# dependencies
#

# shellcheck source=/dev/null
source "scripts/utils.sh"

# Where to clone the dependencies
DEPS_SOURCE_DIR="$SERENE_HOME_DIR/src"

BDWGC_DIR_NAME="bdwgc"
BDWGC_BUILD_DIR="$DEPS_BUILD_DIR/${BDWGC_DIR_NAME}_build"
BDWGC_INSTALL_DIR="$DEPS_BUILD_DIR/$BDWGC_DIR_NAME.$BDWGC_VERSION"

ZSTD_CLI="zstd --ultra -22 -T$(nproc)"
TARGET="x86_64-pc-linux-musl"
COMPILER_ARGS="-fno-sanitize=all"

export TARGET COMPILER_ARGS

# shellcheck source=/dev/null
source "scripts/toolchain.sh"


function build_bdwgc() { ## Builds the BDW GC
    local version
    version="$BDWGC_VERSION"

    repo="${BDWGC_REPO:-https://github.com/ivmai/bdwgc.git}"
    src="$DEPS_SOURCE_DIR/$BDWGC_DIR_NAME.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the BDWGC version '$version'..."
    if [[ -d "$BDWGC_BUILD_DIR.$version" ]]; then
        warn "A build dir for 'BDWGC' already exists at '$BDWGC_BUILD_DIR.$version'"
        warn "Skipping..."
        return
    fi

    mkdir -p "$BDWGC_BUILD_DIR.$version"
    mkdir -p "$BDWGC_INSTALL_DIR"

    _push "$BDWGC_BUILD_DIR.$version"
    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$BDWGC_INSTALL_DIR" \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
          -Dbuild_cord=ON \
          -Denable_atomic_uncollectable=ON \
          -Denable_cplusplus=OFF \
          -Denable_disclaim=ON \
          -Denable_docs=ON \
          -Denable_dynamic_loading=ON \
          -Denable_gc_assertions=ON \
          -Denable_handle_fork=ON \
          -Denable_java_finalization=OFF \
          -Denable_munmap=ON \
          -Denable_parallel_mark=ON \
          -Denable_thread_local_alloc=ON \
          -Denable_threads=ON \
          -Denable_threads_discovery=ON \
          -Denable_throw_bad_alloc_library=ON \
          -Dinstall_headers=ON \
          -DCMAKE_C_COMPILER="$CC" \
          -DCMAKE_CXX_COMPILER="$CXX" \
          "$src"

    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$BDWGC_INSTALL_DIR" -P cmake_install.cmake

    _pop
    info_bdwgc
}

function package_bdwgc() { ## Packages the built toolchain
    local version
    version="$BDWGC_VERSION"

    if [ ! -d "$BDWGC_INSTALL_DIR" ]; then
        error "No installation directory is found at: '$BDWGC_INSTALL_DIR'"
        exit 1
    fi

    info "Packaging the BDWGC version '$version'..."
    _push "$DEPS_BUILD_DIR"
    local pkg
    pkg="$BDWGC_DIR_NAME.$version"
    time tar -I "$ZSTD_CLI" -cf "$pkg.zstd" "$pkg"
    _pop
}

function get_bdwgc_version {
    echo "$BDWGC_VERSION"
}

function push_bdwgc() { ## Push the BDWGC package to the package repository
    local version
    version="$BDWGC_VERSION"

    if [ ! -f "$BDWGC_INSTALL_DIR.zstd" ]; then
        error "No package is found at: '$BDWGC_INSTALL_DIR.zstd'"
        exit 1
    fi

    info "Pushing the BDWGC package version '$version'..."
    _push "$DEPS_BUILD_DIR"
    http_push "$BDWGC_DIR_NAME" "$version"
    echo ""
    info "Done"
    _pop
}

function pull_bdwgc() {
    local version
    version="$BDWGC_VERSION"

    info "Pulling the BDWGC version '$version'..."

    if [ -f "$BDWGC_INSTALL_DIR.zstd" ]; then
        warn "The package is already in the cache at: '$BDWGC_INSTALL_DIR.zstd'"
        return
    fi

    _push "$DEPS_BUILD_DIR"

    if http_pull "$BDWGC_DIR_NAME" "$version" "$BDWGC_INSTALL_DIR.zstd"; then
        info "Unpacking '$BDWGC_INSTALL_DIR.zstd'..."
        unpack "$BDWGC_INSTALL_DIR.zstd"
        echo ""
        info "Done"
    else
        echo ""
        error "Can't find the package."
        exit 4
    fi
    _pop

    info_bdwgc
}

function info_bdwgc() {
    local version
    version="$BDWGC_VERSION"

    info "To activate BDWGC version '$version' add the following env variable to your shell:"
    info "export BDWgc_DIR='$BDWGC_INSTALL_DIR/lib64/cmake/bdwgc'"
}


function build_musl() {
    local version repo src install_dir build_dir toolchain_dir old_path

    version="$MUSL_VERSION"
    #install_dir="$DEPS_BUILD_DIR/musl.0.$version"
    install_dir="$DEPS_BUILD_DIR/llvm.0.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/musl_build.$version"
    toolchain_dir="$DEPS_BUILD_DIR/stage0"
    repo="${MUSL_REPO:-git://git.musl-libc.org/musl}"
    src="$DEPS_SOURCE_DIR/musl.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building musl version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'musl' already exists at '$build_dir'"
        warn "Cleaning up..."
        rm -rf "$build_dir"
    fi

    info "Copy the source to the build directory at: '$build_dir'"
    cp -r "$src" "$build_dir"

    mkdir -p "$install_dir"

    _push "$build_dir"

    old_path="$PATH"

    PATH="$toolchain_dir/bin:$PATH"
    CC="clang"
    #CC="$TARGET-gcc"
    #CFLAGS="$COMPILER_ARGS"
    #CFLAGS="--sysroot $toolchain_dir"

    export CC CFLAGS

    ./configure --prefix="$install_dir"
    make -j "$(nproc)"
    make install

    PATH="$old_path"
    _pop
    info "'musl' version '$version' installed at '$install_dir'"
}

function package_musl() { ## Packages the built toolchain
    local version
    version="$MUSL_VERSION"

    if [ ! -d "$MUSL_INSTALL_DIR" ]; then
        error "No installation directory is found at: '$MUSL_INSTALL_DIR'"
        exit 1
    fi

    info "Packaging the musl version '$version'..."
    _push "$DEPS_BUILD_DIR"
    local pkg
    pkg="$MUSL_DIR_NAME.$version"
    time tar -I "$ZSTD_CLI" -cf "$pkg.zstd" "$pkg"
    _pop
}

function get_musl_version {
    echo "$MUSL_VERSION"
}

function push_musl() {
    local version
    version="$MUSL_VERSION"

    if [ ! -f "$MUSL_INSTALL_DIR.zstd" ]; then
        error "No package is found at: '$MUSL_INSTALL_DIR.zstd'"
        exit 1
    fi

    info "Pushing the musl package version '$version'..."
    _push "$DEPS_BUILD_DIR"
    http_push "$MUSL_DIR_NAME" "$version"
    echo ""
    info "Done"
    _pop
}

function pull_musl() {
    local version
    version="$MUSL_VERSION"

    info "Pulling the musl version '$version'..."

    if [ -f "$MUSL_INSTALL_DIR.zstd" ]; then
        warn "The package is already in the cache at: '$MUSL_INSTALL_DIR.zstd'"
        return
    fi

    _push "$DEPS_BUILD_DIR"

    if http_pull "$MUSL_DIR_NAME" "$version" "$MUSL_INSTALL_DIR.zstd"; then
        info "Unpacking '$MUSL_INSTALL_DIR.zstd'..."
        unpack "$MUSL_INSTALL_DIR.zstd"
        echo ""
        info "Done"
    else
        echo ""
        error "Can't find the package."
        exit 4
    fi
    _pop

    info_musl
}

function manage_dependencies() {
    if [ ! "$1" ]; then
        error "The action is missing."
        exit 1
    fi

    case "$1" in
        "build")
            build_dep "${@:2}"
            ;;
        "package")
            package_dep "${@:2}"
            ;;
        "push")
            push_dep "${@:2}"
            ;;
        "pull")
            pull_dep "${@:2}"
            ;;
        "install")
            install_dependencies "${@:2}"
            ;;
        "version")
            get_dep_version "${@:2}"
            ;;
        *)
            error "Don't know about '$1' action"
            exit 1
        ;;
    esac
}


function pull_dep() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    pull_"$1" "${@:2}"
}

function get_dep_version() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    get_"$1"_version "${@:2}"
}

function build_dep() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    build_"$1" "${@:2}"
}

function package_dep() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    package_"$1" "${@:2}"
}

function push_dep() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    push_"$1" "${@:2}"
}

function pull_dep() {
    if [ ! "$1" ]; then
        error "The dependency name is missing."
        exit 1
    fi

    pull_"$1" "${@:2}"
}

function install_dependencies() {
    info "Looking up the dependencies in the remote repository"
    pull_toolchain || true
    pull_bdwgc || true
}

function unpack() {
    tar -I "$ZSTD_CLI" -xf "$1" -C "$DEPS_BUILD_DIR"
}


function setup_dependencies() {
    if [[ "$SERENE_AUTO_DEP" = "true" ]]; then
        if [ -d "$LLVM_INSTALL_DIR" ]; then
            info "Activating the toolchain at '$LLVM_INSTALL_DIR'..."
            export PATH="$LLVM_INSTALL_DIR/bin:$PATH"

            CC=$(which clang)
            CXX=$(which clang++)
            info "Setting CC to '$CC'"
            info "Setting CXX to '$CXX'"

            #CXXFLAGS="-stdlib=libc++ -lc++abi $CXXFLAGS"
            LDFLAGS="-fuse-ld=lld $LDFLAGS"
            info "Switching to LLD."

            export CC
            export CXX
            export LDFLAGS
            #export CXXFLAGS
        fi
        if [ -d "$BDWGC_INSTALL_DIR" ]; then
            info "Activating the BDWGC at '$BDWGC_INSTALL_DIR'..."

            BDWgc_DIR="$BDWGC_INSTALL_DIR/lib64/cmake/bdwgc"
            export BDWgc_DIR
        fi
    fi
}
