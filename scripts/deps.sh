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

LLVM_DIR_NAME="llvm"
LLVM_DIR="$ME/deps/llvm-project"
LLVM_SOURCE_DIR="$LLVM_DIR/$LLVM_DIR_NAME"
LLVM_BUILD_DIR="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build"
LLVM_INSTALL_DIR="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.$(get_version "$LLVM_DIR")"

BDWGC_DIR_NAME="bdwgc"
BDWGC_SOURCE_DIR="$ME/deps/$BDWGC_DIR_NAME"
BDWGC_BUILD_DIR="$DEPS_BUILD_DIR/${BDWGC_DIR_NAME}_build"
BDWGC_INSTALL_DIR="$DEPS_BUILD_DIR/$BDWGC_DIR_NAME.$(get_version "$BDWGC_SOURCE_DIR")"

IWYU_DIR="$ME/deps/include-what-you-use"

ZSTD_CLI="zstd --ultra -22 -T$(nproc)"

function build_toolchain() { ## Build LLVM and the toolchain
    local version
    version=$(get_version "$LLVM_DIR")

    info "Building the toolchain version '$version'..."

    if [[ -d "$LLVM_BUILD_DIR.$version" ]]; then
        warn "A build dir for 'llvm' already exists at '$LLVM_BUILD_DIR.$version'"
    fi

    mkdir -p "$LLVM_BUILD_DIR.$version"
    mkdir -p "$LLVM_INSTALL_DIR"

    # TODO: Check for ccache
    # TODO: Check for LLD and Clang
    _push "$LLVM_BUILD_DIR.$version"
    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_BUILD_EXAMPLES=OFF \
          -DLLVM_TARGETS_TO_BUILD="$TARGET_ARCHS" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_EXTERNAL_PROJECTS=iwyu \
          -DLLVM_EXTERNAL_IWYU_SOURCE_DIR="$IWYU_DIR" \
          -DLLVM_ENABLE_ASSERTIONS=ON \
          -DLLVM_CCACHE_BUILD=ON \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DLLVM_ENABLE_PROJECTS='clang;lldb;lld;mlir;clang-tools-extra' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          -DCMAKE_C_COMPILER="$CC" \
          -DCMAKE_CXX_COMPILER="$CXX" \
          -DLLVM_ENABLE_LLD=ON \
          "$LLVM_SOURCE_DIR"

    cmake --build . --parallel
    cmake --build . --target check-mlir
    cmake --build . --target check-cxx
    cmake --build . --target check-cxxabi
    cmake --build . --target check-unwind
    cmake -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" -P cmake_install.cmake
    _pop
    info_toolchain
}

function package_toolchain() { ## Packages the built toolchain
    local version
    version=$(get_version "$LLVM_DIR")

    if [ ! -d "$LLVM_INSTALL_DIR" ]; then
        error "No installation directory is found at: '$LLVM_INSTALL_DIR'"
        exit 1
    fi

    info "Packaging the toolchain version '$version'..."
    _push "$DEPS_BUILD_DIR"
    local pkg
    pkg="$LLVM_DIR_NAME.$version"
    time tar -I "$ZSTD_CLI" -cf "$pkg.zstd" "$pkg"
    _pop
}

function push_toolchain() { ## Push the toolchain to the package repository
    local version
    version=$(get_version "$LLVM_DIR")

    if [ ! -f "$LLVM_INSTALL_DIR.zstd" ]; then
        error "No package is found at: '$LLVM_INSTALL_DIR.zstd'"
        exit 1
    fi

    info "Pushing the toolchain version '$version'..."
    _push "$DEPS_BUILD_DIR"
    http_push "$LLVM_DIR_NAME" "$version"
    echo ""
    info "Done"
    _pop
}

function pull_toolchain() {
    local version
    version=$(get_version "$LLVM_DIR")

    info "Pulling the toolchain version '$version'..."

    if [ -f "$LLVM_INSTALL_DIR.zstd" ]; then
        warn "The package is already in the cache at: '$LLVM_INSTALL_DIR.zstd'"
        return
    fi

    _push "$DEPS_BUILD_DIR"
    if http_pull "$LLVM_DIR_NAME" "$version" "$LLVM_INSTALL_DIR.zstd"; then
        unpack "$LLVM_INSTALL_DIR.zstd"
        echo ""
        info "Done"
    else
        echo ""
        error "Can't find the package."
        exit 4
    fi
    _pop
    info_toolchain
}

get_toolchain_version() {
    get_version "$LLVM_DIR"
}

function info_toolchain() {
    local version
    version=$(get_version "$LLVM_DIR")

    info "To activate toolchain version '$version' add the following env variable to your shell:"

    info "export PATH=$LLVM_INSTALL_DIR/bin:\$PATH"
}

function build_bdwgc() { ## Builds the BDW GC
    local version
    version=$(get_version "$BDWGC_SOURCE_DIR")

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
          -Denable_register_main_static_da=ON \
          -Denable_thread_local_alloc=ON \
          -Denable_threads=ON \
          -Denable_threads_discovery=ON \
          -Denable_throw_bad_alloc_library=ON \
          -Dinstall_headers=ON \
          -DCMAKE_C_COMPILER="$CC" \
          -DCMAKE_CXX_COMPILER="$CXX" \
          "$BDWGC_SOURCE_DIR"

    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$BDWGC_INSTALL_DIR" -P cmake_install.cmake

    _pop
    info_bdwgc
}

function package_bdwgc() { ## Packages the built toolchain
    local version
    version=$(get_version "$BDWGC_SOURCE_DIR")

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
    get_version "$BDWGC_SOURCE_DIR"
}

function push_bdwgc() { ## Push the BDWGC package to the package repository
    local version
    version=$(get_version "$BDWGC_SOURCE_DIR")

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
    version=$(get_version "$BDWGC_SOURCE_DIR")

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
    version=$(get_version "$BDWGC_SOURCE_DIR")

    info "To activate BDWGC version '$version' add the following env variable to your shell:"
    info "export BDWgc_DIR='$BDWGC_INSTALL_DIR/lib64/cmake/bdwgc'"
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
