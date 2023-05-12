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

# This file sets up a CMakeCache to build serene for development. In this
# cache file we assume that you are using the toolchain and musl that are
# built by the `builder` script. For example: `builder deps build llvm`
# You still can just build everything yourself but the builder script and
# this file make the process easier.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(triple x86_64-pc-linux-musl)

set(CMAKE_SYSROOT ${SERENE_TOOLCHAIN_PATH})
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER "clang")
set(CMAKE_C_COMPILER_AR "llvm-ar")
set(CMAKE_C_COMPILER_RANLIB "llvm-ranlib")

set(CMAKE_CXX_COMPILER "clang++")
set(CMAKE_CXX_COMPILER_AR "llvm-ar")
set(CMAKE_CXX_COMPILER_RANLIB "llvm-ranlib")

set(CMAKE_ASM_COMPILER "clang")
set(CMAKE_ASM_COMPILER_AR "llvm-ar")
set(CMAKE_ASM_COMPILER_RANLIB "llvm-ranlib")

set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER_TARGET ${triple})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
