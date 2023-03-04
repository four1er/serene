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

# This file sets up a CMakeCache for a LLVM toolchain build

#Enable LLVM projects and runtimes
set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

# Distributions should never be built using the BUILD_SHARED_LIBS CMake option.
# That option exists for optimizing developer workflow only. Due to design and
# implementation decisions, LLVM relies on global data which can end up being
# duplicated across shared libraries resulting in bugs. As such this is not a
# safe way to distribute LLVM or LLVM-based tools.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "")

# Enable libc++
set(LLVM_ENABLE_LIBCXX ON CACHE BOOL "")
set(LLVM_STATIC_LINK_CXX_STDLIB OFF CACHE BOOL "")
set(LLVM_BUILD_STATIC ON CACHE BOOL "")
set(LLVM_BUILD_LLVM_DYLIB OFF CACHE BOOL "")
# This option causes a weird error with the build system that misjudge the
# arch to elf32-i386
#set(COMPILER_RT_USE_LLVM_UNWINDER ON CACHE BOOL "")
set(LLVM_ENABLE_EH ON CACHE BOOL "")
set(LLVM_ENABLE_RTTI ON CACHE BOOL "")

set(LLVM_DEFAULT_TARGET_TRIPLE x86_64-pc-linux-gnu CACHE STRING "")
set(COMPILER_RT_DEFAULT_TARGET_TRIPLE x86_64-pc-linux-gnu CACHE STRING "")
set(LLVM_HOST_TRIPLE x86_64-pc-linux-gnu CACHE STRING "")

set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
# Create the builtin libs of compiler-rt
set(COMPILER_RT_BUILD_BUILTINS ON CACHE BOOL "")
set(COMPILER_RT_BUILD_STANDALONE_LIBATOMIC OFF CACHE BOOL "")
set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
set(COMPILER_RT_EXCLUDE_ATOMIC_BUILTIN OFF CACHE BOOL "")
set(COMPILER_RT_STATIC_CXX_LIBRARY ON CACHE BOOL "")
set(COMPILER_RT_CXX_LIBRARY "libcxx" CACHE STRING "")
set(COMPILER_RT_USE_LIBCXX ON CACHE BOOL "Enable compiler-rt to use libc++ from the source tree")


set(LIBUNWIND_ENABLE_STATIC ON CACHE BOOL "")
set(LIBCXXABI_ENABLE_STATIC ON CACHE BOOL "")
set(LIBCXX_ENABLE_STATIC ON CACHE BOOL "")
set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXX_CXX_ABI libcxxabi CACHE BOOL "")
set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
set(LIBCXX_HAS_GCC_LIB OFF CACHE BOOL "")

set(CLANG_DEFAULT_CXX_STDLIB "libc++" CACHE STRING "")
set(CLANG_DEFAULT_RTLIB "compiler-rt" CACHE STRING "")
set(CLANG_DEFAULT_UNWINDLIB "libunwind" CACHE STRING "")
set(LIBCLANG_BUILD_STATIC ON CACHE BOOL "")

set(LLVM_ENABLE_LIBXML2 OFF CACHE BOOL "")
set(LLVM_ENABLE_TERMINFO OFF CACHE BOOL "")
set(LLVM_ENABLE_LIBEDIT OFF CACHE BOOL "")
set(LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")

#set(LIBUNWIND_ENABLE_CROSS_UNWINDING ON CACHE BOOL "")

# Only build the native target in stage1 since it is a throwaway build.
set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "")

# Optimize the stage1 compiler, but don't LTO it because that wastes time.
set(CMAKE_BUILD_TYPE Release CACHE STRING "")

# Setup vendor-specific settings.
# set(PACKAGE_VENDOR serene-lang.org CACHE STRING "")

# TODO: Turn this on for the final build
# Setting up the stage2 LTO option needs to be done on the stage1 build so that
# the proper LTO library dependencies can be connected.
set(LLVM_ENABLE_LTO OFF CACHE BOOL "")

# Since LLVM_ENABLE_LTO is ON we need a LTO capable linker
set(LLVM_ENABLE_LLD ON CACHE BOOL "")

# project(dummy CXX)
# include(CheckLinkerFlag)
# check_linker_flag(CXX "-stdlib=libc++" CXX_LINKER_SUPPORTS_STDLIB)

# if(NOT CXX_LINKER_SUPPORTS_STDLIB)
#   message(FATAL_ERROR "hnthnthnt")
# else()
#   message(FATAL_ERROR "eeeeEeeeeeeehnthnthnt ${}")
# endif()
# set(CMAKE_COMPILE_WARNING_AS_ERROR ON CACHE BOOL "")
