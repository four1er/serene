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



function unpack() {
    local zstd
    zstd="zstd --ultra -22 -T$(nproc)"

    mkdir -p "$2"
    _push "$2"
    tar -I "$zstd" -xf "$1"
    _pop
}

function pull_toolchain() {
    local toolchain_name
    toolchain_name="serene_toolchain.$LLVM_MAJOR_VERSION.$LLVM_VERSION"

    if [ -f "$TOOLCHAIN_DIR/$toolchain_name.tar.zstd" ]; then
        info "Skip downloading the toolchain. It is already there."
    else
        info "Pulling down the toolchain..."
        http_pull "serene_toolchain" "$LLVM_MAJOR_VERSION.$LLVM_VERSION" "$TOOLCHAIN_DIR/$toolchain_name.tar.zstd"
    fi

    if [ -d "$TOOLCHAIN_DIR/$toolchain_name" ]; then
        info "Skip unpacking the toolchain. It is already there."
        return
    fi

    info "Unpacking the toolchain..."
    unpack "$TOOLCHAIN_DIR/$toolchain_name.tar.zstd" "$TOOLCHAIN_DIR/$toolchain_name"
}

function setup_toolchain() {
    local toolchain_name
    toolchain_name="serene_toolchain.$LLVM_MAJOR_VERSION.$LLVM_VERSION"

    if [[ "$USE_SERENE_TOOLCHAIN" != "true" ]]; then
        warn "Serene toolchain is disabled!"
    else
        pull_toolchain
        export PATH="$TOOLCHAIN_DIR/$toolchain_name/bin:$PATH"
        export SERENE_TOOLCHAIN_PATH="$TOOLCHAIN_DIR/$toolchain_name"

    fi
}
