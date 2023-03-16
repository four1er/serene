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

DOCKER_IMAGE="devheroes.codes/serene/stage0-toolchain"
DOCKER_TAG="latest"

SYSROOTS_PATH="$SERENE_HOME_DIR/sysroots/"

# This function is kind of a hardcoded function.
# It will create a sysroot that supposed to be an alpine
# and replace the alpine vendor to pc or better to say
# it replaces x86_64-alpine-linux-musl with the TARGET
# so it is hardcoded in the sense that it excepts
# x86_64-alpine-linux-musl triple to be in the original
# sysroot
function build_sysroot() {
    local output alpines
    output="$SYSROOTS_PATH/$TARGET"

    mkdir -p "$output"

    _push "$ME/resources/docker/toolchain/stage0"
    docker build -f Sysroot -t devheroes.codes/serene/sysroot0-toolchain:latest .
    docker run -d --name sysroot devheroes.codes/serene/sysroot0-toolchain:latest
    docker export --output sysroot.tar sysroot
    docker stop sysroot
    docker rm sysroot
    mkdir -p "$output"
    tar xf sysroot.tar -C "$output"
    rm sysroot.tar
    _pop

    _push "$output"
    alpines=$(find . -type d -iname "*-alpine-*")

    for i in $alpines; do
        mv -v "$i" "${i//x86_64-alpine-linux-musl/$TARGET}"
    done
    _pop
}

function run_in_container() {
    docker run -it -d \
           -v "$ME:/home/serene/serene" \
           -v "$SERENE_HOME_DIR:/home/serene/.serene/" \
           --user "$(id -u):$(id -g)" \
           --name "stage0" \
           "$DOCKER_IMAGE:$DOCKER_TAG" \
           "$@"
}

function build_musl_cc() {
    local type
    type="native"
    if [ ! -f "$DEPS_SOURCE_DIR/musl_cc.tgz" ]; then
        curl "https://musl.cc/x86_64-linux-musl-$type.tgz" -o "$DEPS_SOURCE_DIR/musl_cc.tgz"
    fi

    if [ ! -d "$DEPS_BUILD_DIR/stage0" ]; then
        tar zxf "$DEPS_SOURCE_DIR/musl_cc.tgz" -C "$DEPS_BUILD_DIR"
        mv -v "$DEPS_BUILD_DIR/x86_64-linux-musl-$type" "$DEPS_BUILD_DIR/stage0"
    fi
}

function build_gcc() {
    local version repo src install_dir build_dir

    repo="${STAGE0_REPO:-https://devheroes.codes/Serene/musl-cross-make.git}"
    src="$DEPS_SOURCE_DIR/musl-cross-make"
    install_dir="$DEPS_BUILD_DIR/stage0"
    build_dir="$DEPS_BUILD_DIR/stage0_build"

    clone_dep "$repo" "master" "$src"

    cp -r "$src" "$build_dir"
    _push "$build_dir"
    {
        echo "TARGET = x86_64-pc-linux-musl"
        echo "GCC_VER = 11.2.0"
        echo "COMMON_CONFIG += CFLAGS='-g0 -Os' CXXFLAGS='-g0 -Os' LDFLAGS='-s'"
        echo "OUTPUT='$install_dir'"
        echo "GCC_CONFIG += --enable-default-pie"
        echo "GCC_CONFIG += --with-static-standard-libraries"
    } >> "$build_dir/config.mak"

    make -j "$(nproc)"
    make install
    _pop
}

function build_docker_gcc() {
    run_in_container ./builder deps build gcc
}

function build_stagex() {
    local version repo src install_dir build_dir old_path stage cache_file llvm_dir
    stage="$1"
    cache_file="$2"

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$DEPS_BUILD_DIR/llvm.$stage.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.$stage.$version"

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
    echo "Using $(nproc) jobs"

    llvm_dir="$(dirname "$(which clang)/..")"
    export install_dir
    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DTARGET_ARCHS="$TARGET_ARCHS" \
          -DTARGET="$TARGET" \
          -DNATIVE_LLVM_DIR="$llvm_dir" \
          -DSERENE_SYSROOT="$HOME/.serene/sysroots/x86_64-linux-musl" \
          "${@:3}" -C "$cache_file" \
          -DLIBCXX_HAS_MUSL_LIBC=ON \
          -DRUNTIMES_"${TARGET}"_LIBCXX_HAS_MUSL_LIBC=ON \
          -DLLVM_NATIVE_TOOL_DIR="$llvm_dir/bin" \
          -DLLVM_HOST_TRIPLE="$TARGET" \
          -DLLVM_TABLEGEN="$(which llvm-tblgen)" \
          -DLLVM_AR="$(which llvm-ar)" \
          -DCMAKE_C_COMPILER_AR="$(which llvm-ar)" \
          -DCMAKE_CXX_COMPILER_AR="$(which llvm-ar)" \
          -DCMAKE_ASM_COMPILER_AR="$(which llvm-ar)" \
          -DCLANG_TABLEGEN="$(which clang-tblgen)" \
          -S "$src/llvm"
    #          -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET" \
    #cmake --build . --parallel
    ninja runtimes -j "$(nproc)"
    ninja install-runtimes
    #-DCMAKE_TOOLCHAIN_FILE="$ME/cmake/toolchains/stage0.cmake" \
    #cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake
    _pop

    info "llvm build is ready at '$install_dir'"
    info "Just add the 'bin' dir to you PATH"

    unset install_dir
}

function build_stage0() {
    local version repo src install_dir build_dir old_path stage cache_file llvm_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$DEPS_BUILD_DIR/stage0"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.0.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage0 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'toolchain' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"
    echo "Using $(nproc) jobs"

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -C "$ME/cmake/caches/stage0.cmake" \
          -S "$src/llvm"
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake
    _pop

    # Enable the lld linker as the default linker for this toolchain
    ln -s "$install_dir/bin/ld.lld" "$install_dir/bin/ld"


    info "llvm build is ready at '$install_dir'"
    info "Just add the 'bin' dir to you PATH"

    unset install_dir
}

function build_stage1 {
    local sysroot tc old_path
    sysroot="$HOME/.serene/sysroots/$TARGET"
    tc="$DEPS_BUILD_DIR/stage0"

    old_path="$PATH"
    PATH="$tc/bin:$PATH"
    CC="$tc/bin/clang --target=$TARGET $COMPILER_ARGS --sysroot $sysroot -static"
    CXX="$tc/bin/clang++ --target=$TARGET $COMPILER_ARGS --sysroot $sysroot -static"

    LDFLAGS="-fuse-ld=lld -L$sysroot/usr/lib -L/usr/lib" #
    export CC CXX LDFLAGS PATH

    build_stagex "1" "$ME/cmake/caches/runtimes.0.cmake"

    unset CC CXX LDFLAGS
    PATH="$old_path"
}

function build_docker_stage0 {
    run_in_container ./builder deps build stage0
}

function build_docker_musl {
    run_in_container ./builder deps build musl
}

function build_stage2 {
    local tc llvm
    tc="$DEPS_BUILD_DIR/musl.0.$MUSL_VERSION"
    llvm="$DEPS_BUILD_DIR/llvm.0.$LLVM_VERSION"
    CC="clang"
    CXX="$CC"


    CFLAGS="$COMPILER_ARGS -isystem $llvm/include/$TARGET/c++/v1/ -isystem $llvm/include/$TARGET/ -isystem $llvm/include/c++/v1/ -isystem $llvm/include/ -isystem $tc/include"
    CXXFLAGS="$CFLAGS"
    LDFLAGS="-fuse-ld=lld -nostdinc -L$llvm/lib -L$tc/lib -lc"
    export CC CXX CFALGS CXXFLAGS LDFLAGS

    build_stagex "2" "$ME/cmake/caches/clang.1.cmake"
    unset CC CXX CXXFLAGS CFLAGS
}

function build_docker_stage2 {
    run_in_container ./builder deps build stage1
}

function build_stage3 {
    build_stagex "3" "$ME/cmake/caches/clang.cmake"
}

function build_llvm() {
    local version repo src install_dir build_dir old_path

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

    old_path="$PATH"
    PATH="$DEPS_BUILD_DIR/stage0/bin:$PATH"
    CC="$DEPS_BUILD_DIR/stage0/bin/x86_64-pc-linux-musl-gcc"
    CXX="$DEPS_BUILD_DIR/stage0/bin/x86_64-pc-linux-musl-g++"
    CFLAGS=" -v"
    CXXFLAGS="$CFLAGS"
    # LDFLAGS="-flto=thin"
    export CC CXX CFLAGS CXXFLAGS

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_EXTERNAL_IWYU_SOURCE_DIR="$iwyu_src" \
          -DTARGET_ARCHS="$TARGET_ARCHS" \
          -C "$ME/cmake/caches/llvm.cmake" \
          -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-pc-linux-musl" \
          -DCMAKE_SYSROOT="$DEPS_BUILD_DIR/stage0/" \
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

function build_llvm_musl() {
    local version repo src install_dir build_dir toolchain_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$DEPS_BUILD_DIR/llvm.2.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.2.$version"
    #toolchain_dir="$DEPS_BUILD_DIR/llvm.1.$LLVM_VERSION"
    toolchain_dir="$DEPS_BUILD_DIR/musl.$MUSL_VERSION"
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

    local old_path
    old_path="$PATH"

    PATH="$toolchain_dir/bin/:$PATH"
    CC="$toolchain_dir/bin/musl-gcc"
    CXX="$toolchain_dir/bin/musl-gcc"
    CC=$(which gcc)
    CXX=$(which g++)
    # CFLAGS="-flto=thin"
    # CXXFLAGS="$CFLAGS"
    # LDFLAGS="-flto=thin"
    export CC CXX
          # -DCMAKE_C_COMPILER_AR="$toolchain_dir/bin/llvm-ar" \
          # -DCMAKE_C_COMPILER_RANLIB="$toolchain_dir/bin/llvm-ranlib" \

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_EXTERNAL_IWYU_SOURCE_DIR="$iwyu_src" \
          -DTARGET_ARCHS="$TARGET_ARCHS" \
          -C "$ME/cmake/caches/llvm.cmake" \
          -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-pc-linux-musl" \
          -S "$src/llvm"
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    unset CC
    unset CXX

    PATH="$old_path"
    _pop

    # Enable the lld linker as the default linker for this toolchain
    ln -s "$install_dir/bin/ld.lld" "$install_dir/bin/ld"

    info "llvm build is ready at '$install_dir'"
    info "Just add the 'bin' dir to you PATH"
}


function build_musl_base() {
    local version repo src build_dir install_dir old_path tc


    version="$MUSL_VERSION"
    install_dir="$DEPS_BUILD_DIR/musl.0.$version"
    #install_dir="$STAGE1_DIR.tmp"
    tc="$DEPS_BUILD_DIR/llvm.0.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/musl_build.0.$version"
    repo="${MUSL_REPO:-git://git.musl-libc.org/musl}"
    src="$DEPS_SOURCE_DIR/musl.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage2 musl version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'musl' already exists at '$build_dir'"
        warn "Cleaning up..."
        rm -rf "$build_dir"
    fi

    info "Copy the source to the build directory at: '$build_dir'"
    cp -r "$src" "$build_dir"

    mkdir -p "$install_dir"

    _push "$build_dir"

    CC=$(which clang)
    LDFLAGS="-fuse-ld=lld"

    export CC CXX LDFLAGS PATH LDFLAGS

    ./configure --prefix="$install_dir"

    make -j "$(nproc)"
    make install
    ln -sv "$install_dir/lib/libc.so" "$install_dir/lib/ld-musl-$(uname -m).so.1"

    # Create a symlink that can be used to print
    # the required shared objects of a program or
    # shared object
    ln -sv "$install_dir/lib/libc.so" "$install_dir/bin/ldd"

    # Configure the dynamic linker
    mkdir -p "$install_dir/etc"
    {
        echo "$install_dir/lib"
        echo "$install_dir/x86_64-unknown-linux-gnu/lib"
        echo "$install_dir/usr/lib64"
        echo "$install_dir/lib64"
        echo "$install_dir/usr/lib"
        echo "$STAGE0_DIR/lib"
        echo "$STAGE0_DIR/x86_64-pc-linux-gnu/lib"
        echo "$STAGE0_DIR/usr/lib64"
        echo "$STAGE0_DIR/lib64"
        echo "$STAGE0_DIR/usr/lib"
        echo "$GCC_INSTALLATION/lib"
    } >> "$install_dir/etc/ld-musl-$(uname -m).path"

    cp -v "$ME/scripts/templates/musl-clang" "$install_dir/bin/"
    chmod +x "$install_dir/bin/musl-clang"
    sed -i "s'@CC@'$CC'" "$install_dir/bin/musl-clang"
    sed -i "s'@PREFIX@'$install_dir'" "$install_dir/bin/musl-clang"
    sed -i "s'@INCDIR@'$install_dir/include'" "$install_dir/bin/musl-clang"
    sed -i "s'@LIBDIR@'$install_dir/lib'" "$install_dir/bin/musl-clang"
    sed -i "s'@BASE_CLANG@'$tc'" "$install_dir/bin/musl-clang"
    sed -i "s'@TARGET@'$TARGET'" "$install_dir/bin/musl-clang"

    cp -v "$ME/scripts/templates/ld.musl-lld" "$install_dir/bin/"
    chmod +x "$install_dir/bin/ld.musl-lld"
    sed -i "s'@CC@'$CC'" "$install_dir/bin/ld.musl-lld"
    sed -i "s'@LIBDIR@'$install_dir/lib'" "$install_dir/bin/ld.musl-lld"
    # TODO: [toolchain] Hardcoded value for dynamic linker of musl is BAAAAD
    #       idea. We need a way to make sure the name is correct
    sed -i "s'@LDSO@'/lib/ld-musl-x86_64.so.1'" "$install_dir/bin/ld.musl-lld"
    # /TODO
    echo -e "#include <string.h>\nint main() {return 0;}" > "$install_dir/main.cpp"

    $CC -stdlib=libc++ -static "$install_dir/main.cpp" -o "$install_dir/main" -fuse-ld=lld -v

    unset CC CXX LDFLAGS

    PATH="$old_path"
    export PATH

    _pop
    info "Stage1 musl has been built at: '$install_dir'"
}


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
        "stage0")
            build_stage0
            ;;
        "stage1")
            build_stage1
            ;;
        "llvm_musl")
            build_llvm_musl
            ;;
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

function build_zlib() {
    local version repo src install_dir build_dir old_path stage cc cxx
    stage="$1"

    version="v1.2.13"
    repo="https://github.com/madler/zlib.git"
    src="$DEPS_SOURCE_DIR/zlib.$version"
    install_dir="$DEPS_BUILD_DIR/llvm.$stage.$LLVM_VERSION"
    build_dir="$DEPS_BUILD_DIR/zlib.$stage.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage$stage zlib version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'zlib' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"
    echo "Using $(nproc) jobs"

    old_path="$PATH"
    PATH="$install_dir/bin/:$PATH"
    cc="$install_dir/bin/clang"
    cxx="$install_dir/bin/clang++"

    # install prefix adn cmake prefix "$ROOTDIR/out/$TARGET-$MCPU"

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DCMAKE_PREFIX_PATH="$install_dir" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CROSSCOMPILING=True \
          -DCMAKE_SYSTEM_NAME="Linux" \
          -DCMAKE_C_COMPILER="$cc;-fno-sanitize=all;-s;-target;$TARGET;--rtlib=compiler-rt" \
          -DCMAKE_CXX_COMPILER="$cxx;-fno-sanitize=all;-s;-target;$TARGET;--rtlib=compiler-rt" \
          -DCMAKE_ASM_COMPILER="$cc;-fno-sanitize=all;-s;-target;$TARGET" \
          -DCMAKE_RC_COMPILER="$install_dir/bin/llvm-rc" \
          -DCMAKE_AR="$install_dir/bin/llvm-ar" \
          -DCMAKE_RANLIB="$install_dir/bin/llvm-ranlib" \
          -S "$src"
    unset install_dir
    cmake --build . -j "$(nproc)" --target install
    _pop

    PATH="$old_path"
    info "zlib build is ready at '$install_dir'"
}

function build_docker_zlib() {
    run_in_container ./builder deps build zlib 0
}
