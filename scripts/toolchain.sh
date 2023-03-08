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
# This file contains the build script for all the steps necessary to have a
# portable llvm toolchain

LLVM_DIR_NAME="llvm"

DOCKER_IMAGE="serene/toolchain-base"
DOCKER_TAG="latest"


function run_in_container() {
    docker run --rm -t \
           -v "$ME:/home/serene/serene" \
           -v "$SERENE_HOME_DIR:/home/serene/.serene/" \
           --user "$(id -u):$(id -g)" \
           "$DOCKER_IMAGE:$DOCKER_TAG" \
           "$@"
}


function build_llvm() {
    local version repo src install_dir build_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$DEPS_BUILD_DIR/llvm.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.$version"

    clone_dep "$repo" "$version" "$src"

    local iwyu_src iwyu_repo
    iwyu_src="$DEPS_SOURCE_DIR/iwyu.$IWYU_VERSION"
    iwyu_repo="${IWYU_REPO:-https://github.com/include-what-you-use/include-what-you-use.git}"
    clone_dep "$iwyu_repo" "$IWYU_VERSION" "$iwyu_src"

    info "Building the stage0 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'toolchain' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"

    CC=$(which clang)
    CXX=$(which clang++)
    # CFLAGS="-flto=thin"
    # CXXFLAGS="$CFLAGS"
    # LDFLAGS="-flto=thin"
    export CC CXX

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_EXTERNAL_IWYU_SOURCE_DIR="$iwyu_src" \
          -DTARGET_ARCHS="$TARGET_ARCHS" \
          -C "$ME/cmake/caches/llvm.cmake" \
          -S "$src/llvm"
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    unset CC
    unset CXX
    _pop

    # Enable the lld linker as the default linker for this toolchain
    ln -s "$install_dir/bin/ld.lld" "$install_dir/bin/ld"

    info "llvm build is ready at '$install_dir'"
    info "Just add the 'bin' dir to you PATH"
}


# function build_musl_stage1() {
#     local version repo src build_dir install_dir old_path stage1

#     version="$MUSL_VERSION"
#     install_dir="$DEPS_BUILD_DIR/musl.stage1.$version"
#     #install_dir="$STAGE1_DIR.tmp"
#     build_dir="$DEPS_BUILD_DIR/${MUSL_DIR_NAME}_build.stage1.$version"
#     repo="${MUSL_REPO:-git://git.musl-libc.org/musl}"
#     src="$DEPS_SOURCE_DIR/$MUSL_DIR_NAME.$version"

#     clone_dep "$repo" "$version" "$src"

#     info "Building the stage2 musl version '$version'..."
#     if [[ -d "$build_dir" ]]; then
#         warn "A build dir for 'musl' already exists at '$build_dir'"
#         warn "Cleaning up..."
#         rm -rf "$build_dir"
#     fi

#     info "Copy the source to the build directory at: '$build_dir'"
#     cp -r "$src" "$build_dir"

#     mkdir -p "$install_dir"

#     _push "$build_dir"

#     old_path="$PATH"
#     PATH="$STAGE0_DIR/bin:$PATH"
#     CC=$(which clang)
#     CXX=$(which clang++)
#     LDFLAGS="-fuse-ld=lld"

#     export CC CXX LDFLAGS PATH LDFLAGS

#     ./configure --prefix="$install_dir"

#     make -j "$(nproc)"
#     make install
#     ln -sv "$install_dir/lib/libc.so" "$install_dir/lib/ld-musl-$(uname -m).so.1"

#     # Create a symlink that can be used to print
#     # the required shared objects of a program or
#     # shared object
#     # ln -sv "$install_dir/lib/libc.so" "$install_dir/bin/ldd"

#     # # Configure the dynamic linker
#     # mkdir -p "$install_dir/etc"
#     # {
#     #     echo "/usr/lib/gcc/x86_64-pc-linux-gnu/12"
#     #     echo "/usr/lib/gcc/x86_64-pc-linux-gnu/11"
#     #     echo "/usr/lib64/"
#     #     echo "/usr/lib/"
#     #     echo "$STAGE0_DIR/lib/clang/$LLVM_MAJOR_VERSION/lib/x86_64-unknown-linux-gnu"
#     #     echo "$STAGE0_DIR/lib/x86_64-unknown-linux-gnu"
#     #     echo "$install_dir/lib"
#     #     echo "$install_dir/x86_64-unknown-linux-gnu/lib"
#     #     echo "$install_dir/usr/lib64"
#     #     echo "$install_dir/lib64"
#     #     echo "$install_dir/usr/lib"
#     #     echo "$STAGE0_DIR/lib"
#     #     echo "$STAGE0_DIR/x86_64-pc-linux-gnu/lib"
#     #     echo "$STAGE0_DIR/usr/lib64"
#     #     echo "$STAGE0_DIR/lib64"
#     #     echo "$STAGE0_DIR/usr/lib"
#     # } >> "$install_dir/etc/ld-musl-$(uname -m).path"

#     # cp -v "$ME/scripts/templates/musl-clang" "$stage1/bin/"
#     # chmod +x "$stage1/bin/musl-clang"
#     # sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/musl-clang"
#     # sed -i "s'@PREFIX@'$install_dir'" "$stage1/bin/musl-clang"
#     # sed -i "s'@INCDIR@'$install_dir/include'" "$stage1/bin/musl-clang"
#     # sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/musl-clang"

#     # cp -v "$ME/scripts/templates/ld.musl-lld" "$stage1/bin/"
#     # chmod +x "$stage1/bin/ld.musl-lld"
#     # sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/ld.musl-lld"
#     # sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/ld.musl-lld"
#     # TODO: [toolchain] Hardcoded value for dynamic linker of musl is BAAAAD
#     #       idea. We need a way to make sure the name is correct
#     #sed -i "s'@LDSO@'/lib/ld-musl-x86_64.so.1'" "$stage1/bin/ld.musl-lld"
#     # /TODO
#     echo -e "#include <string.h>\nint main() {return 0;}" > "$install_dir/main.cpp"

#     $CXX -stdlib=libc++ -static "$install_dir/main.cpp" -o "$install_dir/main" -fuse-ld=lld -v

#     unset CC CXX LDFLAGS

#     PATH="$old_path"
#     export PATH

#     _pop
#     info "Stage1 musl has been built at: '$install_dir'"
# }


function build_toolchain() {
    local stage
    stage="$1"


    case "$stage" in
        "")
            build_llvm
            ;;
        # "dstage0")
        #     run_in_container ./builder deps build toolchain stage0
        #     ;;
        "llvm")
            build_llvm
            ;;
        *)
            error "Don't know anythings about '$1'"
            exit 1
    esac
}

function package_toolchain() { ## Packages the built toolchain
    local version install_dir
    version="$LLVM_VERSION"
    install_dir="$DEPS_BUILD_DIR/llvm.$LLVM_VERSION"

    if [ ! -d "$install_dir" ]; then
        error "No installation directory is found at: '$install_dir'"
        exit 1
    fi

    info "Packaging the toolchain version '$version'..."
    _push "$DEPS_BUILD_DIR"
    local pkg
    pkg="llvm.$version"
    time tar -I "$ZSTD_CLI" -cf "$pkg.zstd" "$pkg"
    _pop
}

function push_toolchain() { ## Push the toolchain to the package repository
    local version install_dir
    version="$LLVM_VERSION"

    install_dir="$DEPS_BUILD_DIR/llvm.$LLVM_VERSION"

    if [ ! -f "$install_dir.zstd" ]; then
        error "No package is found at: '$install_dir.zstd'"
        exit 1
    fi

    info "Pushing the toolchain version '$version'..."
    _push "$DEPS_BUILD_DIR"
    http_push "llvm" "$version"
    echo ""
    info "Done"
    _pop
}

function pull_toolchain() {
    local version
    version="$LLVM_VERSION"

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
    echo "$LLVM_VESRION"
}

function info_toolchain() {
    local version
    version="$LLVM_VERSION"

    info "To activate toolchain version '$version' add the following env variable to your shell:"

    info "export PATH=$LLVM_INSTALL_DIR/bin:\$PATH"
}
