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

source ./utils.sh

function build_toolchain() { ## Build LLVM and the toolchain
    local version
    version=$(get_version "$LLVM_DIR")

    info "Building the toolchain version '$version'..."

    if [[ -d "$LLVM_BUILD_DIR.$version" ]]; then
        warn "A build dir for 'llvm' already exists at '$LLVM_BUILD_DIR.$version'"
        warn "Skipping..."
        return
    fi

    mkdir -p "$LLVM_BUILD_DIR.$version"
    mkdir -p "$LLVM_INSTALL_DIR"

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
    cmake -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" -P cmake_install.cmake
    _pop
}

function package_toolchain() { ## Packages the built toolchain
    local version
    version=$(get_version "$LLVM_DIR")

    if [ ! -d "$LLVM_INSTALL_DIR" ]; then
        error "No installation directory is found at: '$LLVM_INSTALL_DIR'"
        exit 1
    fi

    info "Packaging the toolchain version '$version'..."
    time tar -I "$ZSTD_CLI" -C "$DEPS_BUILD_DIR" -cf "$LLVM_INSTALL_DIR.zstd" "$LLVM_INSTALL_DIR"
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
    http "$LLVM_DIR_NAME" "$version"
    info "Done"
    _pop
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
}

function package_bdwgc() { ## Packages the built toolchain
    local version
    version=$(get_version "$BDWGC_SOURCE_DIR")

    if [ ! -d "$BDWGC_INSTALL_DIR" ]; then
        error "No installation directory is found at: '$BDWGC_INSTALL_DIR'"
        exit 1
    fi

    info "Packaging the BDWGC version '$version'..."
    time tar -I "$ZSTD_CLI" -C "$DEPS_BUILD_DIR"  -cf "$BDWGC_INSTALL_DIR.zstd" "$BDWGC_INSTALL_DIR"
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
    http "$BDWGC_DIR_NAME" "$version"
    info "Done"
    _pop
}
