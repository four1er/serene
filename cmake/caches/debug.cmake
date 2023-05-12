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

# Where to find the packages. Packages can be built from source
# or downloaded via the builder script.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "")

set(SERENE_CCACHE_DIR "$ENV{HOME}/.ccache" CACHE STRING "")

set(CMAKE_BUILD_TYPE "Debug")
