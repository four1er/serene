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
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(triple x86_64-unknown-linux-gnu)

set(CMAKE_C_COMPILER "${SERENE_TOOLCHAIN_PATH}/bin/clang")
set(CMAKE_C_COMPILER_TARGET ${triple})

set(CMAKE_CXX_COMPILER "${SERENE_TOOLCHAIN_PATH}/bin/clang++")
set(CMAKE_CXX_COMPILER_TARGET ${triple})

# where is the target environment located
set(CMAKE_FIND_ROOT_PATH "${SERENE_TOOLCHAIN_PATH}")

# adjust the default behavior of the FIND_XXX() commands:
# search programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

message(">>>> ${CMAKE_C_COMPILER} -- ${SERENE_TOOLCHAIN_PATH}")
