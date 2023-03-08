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

# This file sets up a CMakeCache to build serene for development

# Where to find the packages. Packages can be built from source
# or downloaded via the builder script.
message(STATUS "[SERENE] SET THE CONFIG DIR TO: ${SERENE_CONFIG_HOME}")

set(SERENE_PKG_DIR "${SERENE_CONFIG_HOME}/env")

set(SERENE_LLVM_DIR "${SERENE_PKG_DIR}/llvm.${LLVM_VERSION}"
  CACHE STRING "Where to find the llvm installation.")
set(SERENE_LLVM_BIN "${SERENE_LLVM_DIR}/bin")

if(EXISTS ${SERENE_LLVM_DIR})
  message(STATUS "Setting LLVM DIR to: '${SERENE_LLVM_DIR}'")
else()
  message(FATAL_ERROR "Can't find the LLVM dir at: '${SERENE_LLVM_DIR}'")
endif()

# Setting the PATH env var to include the bin dir from the LLVM build
# this is the same as `export PATH="blah/:$PATH". it will not propegate
# to the host shell.
set(ENV{PATH} "${SERENE_LLVM_BIN}:$ENV{PATH}")

set(CMAKE_C_COMPILER "${SERENE_LLVM_BIN}/clang" CACHE PATH "")
set(CMAKE_CXX_COMPILER "${SERENE_LLVM_BIN}/clang++" CACHE PATH "")

# The name of this variable has to be like this(a mix of upper and
# lower case letters). That's due to the package name and it is not
# a mistake
set(BDWgc_DIR "${SERENE_PKG_DIR}/bdwgc.${BDWGC_VERSION}")

set(MUSL_DIR "${SERENE_PKG_DIR}/musl.${MUSL_VERSION}/" CACHE PATH "")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "")
set(SERENE_CCACHE_DIR "$ENV{HOME}/.ccache" CACHE STRING "")
set(CMAKE_BUILD_TYPE "Debug")
