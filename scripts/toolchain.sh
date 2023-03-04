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
LLVM_BUILD_DIR="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build"

MUSL_DIR_NAME="musl"
STAGE0_DIR="$DEPS_BUILD_DIR/stage0.$LLVM_VERSION.$MUSL_VERSION"
STAGE1_DIR="$DEPS_BUILD_DIR/stage1.$LLVM_VERSION.$MUSL_VERSION"
STAGE2_DIR="$DEPS_BUILD_DIR/stage2.$LLVM_VERSION.$MUSL_VERSION"
STAGE2_TC_DIR="$DEPS_BUILD_DIR/stage2_tc.$LLVM_VERSION.$MUSL_VERSION"

function build_toolchain_stage0() {
    local version repo src stage1 old_path install_dir build_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$STAGE0_DIR"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.stage0.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage0 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'toolchain' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"

    export CFLAGS=' -g -g1 '
    export CXXFLAGS="$CFLAGS"
    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -C "$ME/cmake/toolchains/stage1.cmake" \
          -S "$src/llvm"
    cmake --build . --parallel
    # ninja stage2-distribution
    # ninja stage2-install
    # ninja stage2-install-distribution
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    unset CC
    unset CXX

    _pop
    info "Stage0 toolchain build is ready at '$install_dir'"
}


function build_toolchain_stage01() {
    local version repo src stage1 old_path install_dir build_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    install_dir="$STAGE0_DIR"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.stage0.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage0 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'toolchain' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"
    export CFLAGS=' -g -g1 '
    export CXXFLAGS="$CFLAGS"

    local CONFIG_OPTIONS
    # Set the build options ..
    CONFIG_OPTIONS+="-DBUILD_SHARED_LIBS=OFF "
    CONFIG_OPTIONS+="-DLLVM_ENABLE_LIBCXX=ON "
    CONFIG_OPTIONS+="-DLLVM_TARGET_ARCH=X86 "
    CONFIG_OPTIONS+="-DLLVM_TARGETS_TO_BUILD=X86 "
    CONFIG_OPTIONS+="-DLLVM_ENABLE_EH=ON "
    CONFIG_OPTIONS+="-DLLVM_ENABLE_RTTI=ON "
    CONFIG_OPTIONS+="-DLLVM_BUILD_LLVM_DYLIB=ON "

    local CONFIG_CRT
    # Set the flags for Compiler-rt...
    CONFIG_CRT="-DCOMPILER_RT_BUILD_SANITIZERS=OFF"
    CONFIG_CRT+="-DCOMPILER_RT_BUILD_XRAY=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_BUILD_PROFILE=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_BUILD_LIBFUZZER=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_BUILD_ORC=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_CAN_EXECUTE_TESTS=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_HWASAN_WITH_INTERCEPTORS=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_USE_BUILTINS_LIBRARY=OFF "
    CONFIG_CRT+="-DCOMPILER_RT_USE_LLVM_UNWINDER=ON "
    CONFIG_CRT+="-DCOMPILER_RT_BUILD_BUILTINS=ON "
    CONFIG_CRT+="-D COMPILER_RT_BUILD_STANDALONE_LIBATOMIC=ON "

    local CONFIG_CLANG
    # Set the flags for clang:
    CONFIG_CLANG="-DCLANG_DEFAULT_RTLIB=compiler-rt"
    CONFIG_CLANG+="-DCLANG_ENABLE_STATIC_ANALYZER=OFF "
    CONFIG_CLANG+="-DCLANG_ENABLE_ARCMT=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_C_ARCMT_TEST_BUILD=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_AMDGPU_ARCH_BUILD=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_APINOTES_TEST_BUILD=OFF "
    CONFIG_CLANG+="-DCLANG_TOOL_ARCMT_TEST_BUILD=OFF "

    local CONFIG_LIBUNWIND CONFIG_LIBCXXABI CONFIG_LIBCXX
    # Set the flags to prevent build static libraries for
    # libunwind, libcxxabi, and libcxx:
    CONFIG_LIBUNWIND="-DLIBUNWIND_ENABLE_STATIC=OFF "
    CONFIG_LIBCXXABI="-DLIBCXXABI_ENABLE_STATIC=OFF "
    CONFIG_LIBCXX="-DLIBCXX_ENABLE_STATIC=OFF "

    # Set the options for libc++
    CONFIG_LIBCXX+="-DLIBCXX_USE_COMPILER_RT=ON "
    CONFIG_LIBCXX+="-DLIBCXX_CXX_ABI=libcxxabi "
    CONFIG_LIBCXX+="-DLIBCXX_EXTRA_SITE_DEFINES=ON "
    CONFIG_LIBCXX+="-DLIBCXX_ENABLE_ASSERTIONS=ON "
    CONFIG_LIBCXX+="-DLIBCXX_ENABLE_LOCALIZATION=OFF "
    CONFIG_LIBCXX+="-DLIBCXX_ENABLE_VENDOR_AVAILABILITY_ANNOTATIONS=ON "
    CONFIG_LIBCXX+="-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF "

    # Set the options for libc++abi
    CONFIG_LIBCXXABI+="-DLIBCXXABI_ENABLE_FORGIVING_DYNAMIC_CAST=ON "
    CONFIG_LIBCXXABI+="-DLIBCXXABI_USE_COMPILER_RT=ON "
    CONFIG_LIBCXXABI+="-DLIBCXXABI_USE_LLVM_UNWINDER=ON "
    CONFIG_LIBCXXABI+="-DLIBCXX_HAS_GCC_LIB=OFF "
    # Set the options for libunwind
    CONFIG_LIBUNWIND+="-DLIBUNWIND_ENABLE_CROSS_UNWINDING=ON "

    # Set paths...
    local CONFIG_PATHS
    CONFIG_PATHS="-DCMAKE_INSTALL_PREFIX=$install_dir "

    # Turn off unwanted features, docs and tests
    local BUILD_OFF
    BUILD_OFF="-DLLVM_BUILD_TESTS=OFF "
    BUILD_OFF+="-DLLVM_INCLUDE_TESTS=OFF "
    BUILD_OFF+="-DLLVM_INCLUDE_DOCS=OFF "
    BUILD_OFF+="-DLLVM_INCLUDE_EXAMPLES=OFF "
    BUILD_OFF+="-DLLVM_INCLUDE_BENCHMARKS=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_OCAMLDOC=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_BACKTRACES=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_LIBEDIT=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_LIBXML2=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_LIBPFM=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_TERMINFO=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_ZLIB=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_Z3_SOLVER=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_CRASH_OVERRIDES=OFF "
    BUILD_OFF+="-DLLVM_ENABLE_ZSTD=OFF "
    BUILD_OFF+="-DLLVM_APPEND_VC_REV=OFF "
    BUILD_OFF+="-DLIBCXX_INCLUDE_BENCHMARKS=OFF "
    BUILD_OFF+="-DLLVM_TOOL_XCODE_TOOLCHAIN_BUILD=OFF "
    BUILD_OFF+="-DLLVM_TOOL_LLVM_XRAY_BUILD=OFF "
    BUILD_OFF+="-DLLVM_TOOL_LLVM_MICROSOFT_DEMANGLE_FUZZER_BUILD=OFF "
    BUILD_OFF+="-DLLVM_TOOL_LLVM_ITANIUM_DEMANGLE_FUZZER_BUILD=OFF "
    BUILD_OFF+="-DLLVM_TOOL_BUGPOINT_PASSES_BUILD=OFF "
    BUILD_OFF+="-DLLVM_TOOL_BUGPOINT_BUILD=OFF "

    CC="$(which gcc)"
    CXX="$(which g++)"
    export CC CXX

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_TARGETS_TO_BUILD="X86" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_ENABLE_PROJECTS='clang;lld' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          "${CONFIG_TOOLS}" "${CONFIG_TUPLES}" \
          "${CONFIG_CRT}" "${CONFIG_CLANG}" "${CONFIG_OPTIONS}" \
          "${CONFIG_LIBUNWIND}" "${CONFIG_LIBCXXABI}" \
          "${CONFIG_LIBCXX}" "${CONFIG_PATHS}" "${BUILD_OFF}"  \
          -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF \
          -DCOMPILER_RT_BUILD_BUILTINS=ON \
          -DLIBCXX_USE_COMPILER_RT=ON \
          -DLIBCXXABI_USE_COMPILER_RT=ON \
          -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
          -S "$src/llvm"
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    unset CC
    unset CXX

    _pop
    info "Stage0 toolchain build is ready at '$install_dir'"

}

function build_musl_stage1() {
    local version repo src build_dir install_dir old_path stage1

    version="$MUSL_VERSION"
    install_dir="$STAGE1_DIR"
    build_dir="$DEPS_BUILD_DIR/${MUSL_DIR_NAME}_build.stage1.$version"
    repo="${MUSL_REPO:-git://git.musl-libc.org/musl}"
    src="$DEPS_SOURCE_DIR/$MUSL_DIR_NAME.$version"

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

    old_path="$PATH"
    PATH="$STAGE0_DIR/bin:$PATH"
    CC=$(which clang)
    CXX=$(which clang++)
    LDFLAGS="-fuse-ld=lld"

    export CC CXX LDFLAGS PATH LDFLAGS

    ./configure --prefix="$install_dir"

    make -j "$(nproc)"
    make install
    ln -sv "$install_dir/lib/libc.so" "$install_dir/lib/ld-musl-$(uname -m).so.1"

    # Create a symlink that can be used to print
    # the required shared objects of a program or
    # shared object
    # ln -sv "$install_dir/lib/libc.so" "$install_dir/bin/ldd"

    # # Configure the dynamic linker
    # mkdir -p "$install_dir/etc"
    # {
    #     echo "/usr/lib/gcc/x86_64-pc-linux-gnu/12"
    #     echo "/usr/lib/gcc/x86_64-pc-linux-gnu/11"
    #     echo "/usr/lib64/"
    #     echo "/usr/lib/"
    #     echo "$STAGE0_DIR/lib/clang/$LLVM_MAJOR_VERSION/lib/x86_64-unknown-linux-gnu"
    #     echo "$STAGE0_DIR/lib/x86_64-unknown-linux-gnu"
    #     echo "$install_dir/lib"
    #     echo "$install_dir/x86_64-unknown-linux-gnu/lib"
    #     echo "$install_dir/usr/lib64"
    #     echo "$install_dir/lib64"
    #     echo "$install_dir/usr/lib"
    #     echo "$STAGE0_DIR/lib"
    #     echo "$STAGE0_DIR/x86_64-pc-linux-gnu/lib"
    #     echo "$STAGE0_DIR/usr/lib64"
    #     echo "$STAGE0_DIR/lib64"
    #     echo "$STAGE0_DIR/usr/lib"
    # } >> "$install_dir/etc/ld-musl-$(uname -m).path"

    # cp -v "$ME/scripts/templates/musl-clang" "$stage1/bin/"
    # chmod +x "$stage1/bin/musl-clang"
    # sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/musl-clang"
    # sed -i "s'@PREFIX@'$install_dir'" "$stage1/bin/musl-clang"
    # sed -i "s'@INCDIR@'$install_dir/include'" "$stage1/bin/musl-clang"
    # sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/musl-clang"

    # cp -v "$ME/scripts/templates/ld.musl-lld" "$stage1/bin/"
    # chmod +x "$stage1/bin/ld.musl-lld"
    # sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/ld.musl-lld"
    # sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/ld.musl-lld"
    # TODO: [toolchain] Hardcoded value for dynamic linker of musl is BAAAAD
    #       idea. We need a way to make sure the name is correct
    #sed -i "s'@LDSO@'/lib/ld-musl-x86_64.so.1'" "$stage1/bin/ld.musl-lld"
    # /TODO
    echo -e "#include <string.h>\nint main() {return 0;}" > "$install_dir/main.cpp"

    $CXX -stdlib=libc++ -static "$install_dir/main.cpp" -o "$install_dir/main" -fuse-ld=lld -v

    unset CC CXX LDFLAGS

    PATH="$old_path"
    export PATH

    _pop
    info "$(g++ -print-prog-name=libstdc++.so)"
    info "Stage1 musl has been built at: '$install_dir'"
}


function build_toolchain_stage1() {
    local version repo src install_dir build_dir old_path

    version="$LLVM_VERSION"
    install_dir="$STAGE1_DIR"
    build_dir="$LLVM_BUILD_DIR.stage1.$version"

    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"

    clone_dep "$repo" "$version" "$src"

    info "Building the stage1 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "Stage1 build dir already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"


    _push "$LLVM_BUILD_DIR.stage1.$version"
    old_path="$PATH"
    PATH="$STAGE0_DIR/bin:$PATH"

    CC=$(which clang)
    CXX=$(which clang++)

    export CC CXX PATH

    info "Testing libc++ availability..."
    (printf "#include <cstddef>\nint main(){return sizeof(size_t);}" \
        | $CXX -x c++ -stdlib=libc++ -v - || {
        >&2 echo "Need libc++ for this to work"
        exit 1
     }) && {
        info "libc++ looks ok!"
    }

    export CFLAGS=' -g -g1 '
    export CXXFLAGS="$CFLAGS -isystem $STAGE0_DIR/include "
    export LDFLAGS="-fuse-ld=lld -L $STAGE0_DIR/lib/ -lc++abi -L $STAGE0_DIR/lib/x86_64-unknown-linux-gnu"

    # Set the compiler and linker flags...
    #LINKERFLAGS="-Wl,-dynamic-linker $install_dir/lib/ld-musl-x86_64.so.1"

    cmake -G Ninja -Wno-dev \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -C "$ME/cmake/toolchains/stage2.standalone.cmake" \
          "$src/llvm"

          # -DCMAKE_EXE_LINKER_FLAGS="${LINKERFLAGS}" \
          # -DCMAKE_SHARED_LINKER_FLAGS="${LINKERFLAGS}" \

#              -DCMAKE_SYSROOT="$STAGE0_DIR" \
    #-DCMAKE_C_LINK_EXECUTABLE="$STAGE0_DIR/bin/bla" \
    #      -DCMAKE_CXX_LINK_EXECUTABLE="$STAGE0_DIR/bin/bla" \

          # -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
          # -DLLVM_HOST_TRIPLE=x86_64-unknown-linux-musl \
          # -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \

          # -DCMAKE_EXE_LINKER_FLAGS="${LINKERFLAGS}"    \
          # -DCMAKE_SHARED_LINKER_FLAGS="${LINKERFLAGS}" \

          # "${CONFIG_TOOLS}" "${CONFIG_TUPLES}" \
          # "${CONFIG_CRT}" "${CONFIG_CLANG}" "${CONFIG_OPTIONS}" \
          # "${CONFIG_LIBUNWIND}" "${CONFIG_LIBCXXABI}" \
          # "${CONFIG_LIBCXX}" "${CONFIG_PATHS}" "${BUILD_OFF}"  \
          # -DLLVM_ENABLE_PROJECTS="clang;lld" \
          # -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          # -DLLVM_ENABLE_LLD=ON \
          # -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF \
          # -DCOMPILER_RT_BUILD_BUILTINS=ON \
          # -DLIBCXX_USE_COMPILER_RT=ON \
          # -DLIBCXXABI_USE_COMPILER_RT=ON \
          # -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \

          # -DLLVM_BUILD_EXAMPLES=OFF \
          # -DLLVM_TARGETS_TO_BUILD="X86" \
          # -DCMAKE_BUILD_TYPE=Release \
          # -DLLVM_ENABLE_PROJECTS='clang;lld' \

          # -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF \
          # -DCOMPILER_RT_BUILD_BUILTINS=ON \
          # -DLIBCXX_USE_COMPILER_RT=ON \
          # -DLIBCXXABI_USE_COMPILER_RT=ON \
          # -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
          # -DLLVM_INCLUDE_BENCHMARKS=OFF \
          # -DLLVM_ENABLE_LLD=ON \

    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    unset CC CXX LDFLAGS

    PATH="$old_path"
    export PATH

    _pop
    info "Stage1 is ready at '$install_dir'"
}

function build_libcxx_stage2() {
    local version repo src stage1 old_path install_dir build_dir

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    stage1="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.stage1.$version"
    install_dir="$STAGE2_DIR"
    build_dir="$DEPS_BUILD_DIR/libcxx_build.stage2.$version"

    if [ ! -d "$stage1" ]; then
        error "Stage1 compiler is not there yet. Did you forget to build it?"
        exit 1
    fi

    clone_dep "$repo" "$version" "$src"

    info "Building the stage2 libcxx version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for 'libcxx' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"

    old_path="$PATH"
    export PATH="$stage1/bin:$PATH"

    export CC="$stage1/bin/clang"
    export CXX="$stage1/bin/clang++"
    # musl_dir="$DEPS_BUILD_DIR/$MUSL_DIR_NAME.stage2.$version"
    # export CFLAGS="-L $musl_dir/lib -isystem $musl_dir/include -nostdinc"
    # export CXXFLAGS="$CFLAGS"

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_TARGETS_TO_BUILD="X86" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_ENABLE_PROJECTS='clang;lld' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF \
          -DCOMPILER_RT_BUILD_BUILTINS=ON \
          -DLIBCXX_USE_COMPILER_RT=ON \
          -DLIBCXXABI_USE_COMPILER_RT=ON \
          -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
          -DLLVM_ENABLE_LLD=ON \
          -S "$src/llvm"
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    export PATH="$old_path"
    # unset CFLAGS
    # unset CXXFLAGS

    unset CC
    unset CXX

    _pop
    info "Stage2 'libcxx' build is ready at '$install_dir'"
}

function build_musl_stage2() {
    local version repo src build_dir install_dir old_path stage1

    version="$MUSL_VERSION"
    install_dir="$STAGE2_DIR"
    build_dir="$DEPS_BUILD_DIR/${MUSL_DIR_NAME}_build.stage2.$version"
    repo="${MUSL_REPO:-git://git.musl-libc.org/musl}"
    src="$DEPS_SOURCE_DIR/$MUSL_DIR_NAME.$version"
    stage1="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.stage1.$LLVM_VERSION"

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
    old_path="$PATH"
    export PATH="$stage1/bin:$PATH"

    export CC="$stage1/bin/clang"
    export CXX="$stage1/bin/clang++"
    export CFLAGS="-fuse-ld=lld -Os -pipe"
    export LDFLAGS="-fuse-ld=lld"
    export LIBCC="--rtlib=compiler-rt"

    ./configure --disable-shared --prefix="$install_dir"

    make -j "$(nproc)"
    make install

    unset CC
    unset CXX
    unset CFLAGS
    unset LIBCC
    unset LDFLAGS
    export PATH="$old_path"

    cp -v "$ME/scripts/templates/musl-clang" "$stage1/bin/"
    chmod +x "$stage1/bin/musl-clang"
    sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/musl-clang"
    sed -i "s'@PREFIX@'$install_dir'" "$stage1/bin/musl-clang"
    sed -i "s'@INCDIR@'$install_dir/include'" "$stage1/bin/musl-clang"
    sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/musl-clang"

    cp -v "$ME/scripts/templates/ld.musl-lld" "$stage1/bin/"
    chmod +x "$stage1/bin/ld.musl-lld"
    sed -i "s'@CC@'$stage1/bin/clang'" "$stage1/bin/ld.musl-lld"
    sed -i "s'@LIBDIR@'$install_dir/lib'" "$stage1/bin/ld.musl-lld"
    # TODO: [toolchain] Hardcoded value for dynamic linker of musl is BAAAAD
    #       idea. We need a way to make sure the name is correct
    sed -i "s'@LDSO@'/lib/ld-musl-x86_64.so.1'" "$stage1/bin/ld.musl-lld"
    # /TODO

    _pop
    info "Stage2 musl has been built at: '$install_dir'"
}

function build_toolchain_stage2() {
    local version repo src install_dir stage1 build_dir old_path

    version="$LLVM_VERSION"
    install_dir="$STAGE2_TC_DIR"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    # Why not our clang from stage1? Well musl kindly provides a wraper
    # script in the bin directory that uses musl but with the compiler
    # that builds it. So basically `musl-clang` would be a wrapper around
    # stage one clang with musl enabled by default
    stage1="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.stage1.$version"
    install_dir="$STAGE2_TC_DIR"
    build_dir="$DEPS_BUILD_DIR/${LLVM_DIR_NAME}_build.stage2.$version"

    if [ ! -d "$stage1" ]; then
        error "Stage1 compiler is not there yet. Did you forget to build it?"
        exit 1
    fi

    clone_dep "$repo" "$version" "$src"

    info "Building the stage2 toolchain version '$version'..."
    if [[ -d "$build_dir" ]]; then
        warn "A build dir for stage2 'llvm' already exists at '$build_dir'"
    fi

    mkdir -p "$build_dir"
    mkdir -p "$install_dir"

    _push "$build_dir"

    old_path="$PATH"
    export PATH="$STAGE2_DIR/bin:$stage1/bin:$PATH"

    export CC="$stage1/bin/musl-clang"
    export CXX="$stage1/bin/clang++"
    export CXXFALGS="--rtlib=compiler-rt"
    export LDFLAGS="-fuse-ld=musl-lld -v"

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_BUILD_EXAMPLES=OFF \
          -DLLVM_TARGETS_TO_BUILD="$TARGET_ARCHS" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_SYSROOT="$STAGE2_DIR" \
          -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-linux-musl" \
          -DLLVM_TARGET_TRIPLE="x86_64-linux-musl" \
          -DLLVM_ENABLE_BINDINGS=OFF \
          -DLLVM_ENABLE_LIBCXX=ON \
          -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
          -DLIBCXX_USE_COMPILER_RT=ON \
          -DLIBCXXABI_USE_COMPILER_RT=ON \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
          -DCOMPILER_RT_BUILD_BUILTINS=ON \
          -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
          -DLLVM_ENABLE_PROJECTS='clang;lldb;lld;mlir;clang-tools-extra' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          -DCMAKE_C_COMPILER="$CC" \
          -DCMAKE_CXX_COMPILER="$CXX" \
          -DLLVM_INCLUDE_BENCHMARKS=OFF \
          "$src/llvm"
          #-DLLVM_USE_LINKER="$STAGE2_DIR/bin/ld.musl-lld" \
    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    export PATH="$old_path"
    #-DLLVM_ENABLE_LLD=ON \
    unset CC
    unset CXX

    _pop
    info_toolchain
}

function build_toolchain_stage3() {
    local version repo src install_dir stage1 old_path

    version="$LLVM_VERSION"
    repo="${LLVM_REPO:-https://github.com/llvm/llvm-project.git}"
    src="$DEPS_SOURCE_DIR/$LLVM_DIR_NAME.$version"
    stage1="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.stage1.$version"
    install_dir="$DEPS_BUILD_DIR/$LLVM_DIR_NAME.stage2.$version"

    if [ ! -d "$stage1" ]; then
        error "Stage1 compiler is not there yet. Did you forget to build it?"
        exit 1
    fi

    clone_dep "$repo" "$LLVM_VERSION" "$src"

    info "Building the stage2 toolchain version '$version'..."
    if [[ -d "$LLVM_BUILD_DIR.stage2.$version" ]]; then
        warn "A build dir for 'llvm' already exists at '$LLVM_BUILD_DIR.stage2.$version'"
    fi

    mkdir -p "$LLVM_BUILD_DIR.stage2.$version"
    mkdir -p "$install_dir"

    _push "$LLVM_BUILD_DIR.stage2.$version"

    old_path="$PATH"
    export PATH="$stage1/bin:$PATH"

    CC="$stage1/bin/clang"
    CXX="$stage1/bin/clang++"

    cmake -G Ninja \
          -DCMAKE_INSTALL_PREFIX="$install_dir" \
          -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc)" \
          -DLLVM_PARALLEL_LINK_JOBS="$(nproc)" \
          -DLLVM_BUILD_EXAMPLES=OFF \
          -DLLVM_TARGETS_TO_BUILD="$TARGET_ARCHS" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_ENABLE_ASSERTIONS=ON \
          -DLLVM_CCACHE_BUILD=ON \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DLLVM_ENABLE_PROJECTS='clang;lldb;lld;mlir;clang-tools-extra' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          -DCMAKE_C_COMPILER="$CC" \
          -DCMAKE_CXX_COMPILER="$CXX" \
          -DLLVM_ENABLE_LLD=ON \
          "$src/llvm"

    cmake --build . --parallel
    cmake -DCMAKE_INSTALL_PREFIX="$install_dir" -P cmake_install.cmake

    export PATH="$old_path"

    unset CC
    unset CXX

    _pop
    info_toolchain
}

function build_toolchain() {
    local stage
    stage="$1"


    case "$stage" in
        "")
            build_musl_stage1
            build_toolchain_stage1
            build_musl_stage2
            build_libcxx_stage2
            build_toolchain_stage2
            ;;
        "stage0")
            build_toolchain_stage0
            ;;
        "stage1")
            #cp -r "$STAGE0_DIR" "$STAGE1_DIR"
            #build_musl_stage1
            build_toolchain_stage1
            ;;
        "stage2")
            build_musl_stage2
            build_libcxx_stage2
            build_toolchain_stage2
            ;;
        "stage1-musl")
            build_musl_stage1
            ;;
        "stage2-musl")
            build_musl_stage2
            ;;
        "stage2-libcxx")
            build_libcxx_stage2
            ;;
        "stage2-toolchain")
            build_toolchain_stage2
            ;;
        *)
            error "Don't know anythings about '$1'"
            exit 1
    esac
}

function package_toolchain() { ## Packages the built toolchain
    local version
    version="$LLVM_VERSION"

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
    version="$LLVM_VERSION"

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
