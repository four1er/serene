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
cmake_minimum_required(VERSION 3.19)

project(Serene
  VERSION 1.0.0
  DESCRIPTION "A modern typed Lisp."
  LANGUAGES CXX C)

# Clangd command file
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

# =============================================================================
# Policies
# =============================================================================
cmake_policy(SET CMP0116 OLD)

# =============================================================================
# User Options
# =============================================================================
option(CPP_20_SUPPORT "C++20 Support" ON)
option(SERENE_BUILD_TESTING "Enable tests" OFF)
option(SERENE_ENABLE_BUILDID "Enable build id." OFF)
option(SERENE_ENABLE_THINLTO "Enable ThisLTO." ON)
option(SERENE_ENABLE_DOCS "Enable document generation" OFF)
option(SERENE_ENABLE_TIDY "Enable clang tidy check" OFF)
option(SERENE_DISABLE_CCACHE "Disable automatic ccache integration" OFF)
option(SERENE_ENABLE_DEVTOOLS "Enable the devtools build" OFF)
option(SERENE_DISABLE_MUSL "Disable musl libc (Musl is recommended)." OFF)
option(SERENE_DISABLE_LIBCXX "Disable libc++ (libc++ is recommended)." OFF)
option(SERENE_DISABLE_COMPILER_RT
  "Disable compiler-rt (compiler-rt is recommended)." OFF)

# LLVM
# Info about the target llvm build
option(LLVM_USE_PERF "If the target LLVM build is built with LLVM_USE_PERF" OFF)

# Only do these if this is the main project, and not if it is included through add_subdirectory
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
  ## Settings =======================
  # specify the C++ standard
  if (CPP_20_SUPPORT)
    set(CMAKE_CXX_STANDARD 20)
  else()
    set(CMAKE_CXX_STANDARD 17)
  endif()

  set(CMAKE_CXX_STANDARD_REQUIRED True)

  if(SERENE_ENABLE_TIDY)
    find_program(CLANG_TIDY_PATH NAMES clang-tidy REQUIRED)
  endif()

  # We use iwyu intensively. For the version details check out the
  # submodule at `deps/include-what-you-use`
  find_program(iwyu NAMES include-what-you-use iwyu REQUIRED)
  set(iwyu_path ${iwyu})

  # Let's ensure -std=c++xx instead of -std=g++xx
  set(CMAKE_CXX_EXTENSIONS OFF)

  set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
  set(MemoryCheckCommand "valgrind")

  # Let's nicely support folders in IDEs
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)


  # Setup the basic compiler flags
  add_compile_options(
    -Wall
    -Wextra
    -Werror
    -Wpedantic
    -Wabstract-final-class
    -Walloca
    -Warray-bounds-pointer-arithmetic
    -Warray-parameter
    -Wassign-enum
    -Wsign-conversion
    -Wnon-virtual-dtor
    -Wold-style-cast
    -Wcast-align
    -Wunused
    -Woverloaded-virtual
    -Wdouble-promotion
    -Wformat=2)

  # CCache support ==============================
  if(SERENE_DISABLE_CCACHE)
    message(STATUS "CCache support is disabled")
  else()
    find_program(CCACHE_PROGRAM ccache)

    if(CCACHE_PROGRAM)
      message(STATUS "Found CCache")
      set(SERENE_CCACHE_MAXSIZE "" CACHE STRING "Size of ccache")
      set(SERENE_CCACHE_DIR "" CACHE STRING "Directory to keep ccached data")
      set(SERENE_CCACHE_PARAMS "CCACHE_CPP2=yes CCACHE_HASHDIR=yes"
        CACHE STRING "Parameters to pass through to ccache")

      set(CCACHE_PROGRAM "${SERENE_CCACHE_PARAMS} ${CCACHE_PROGRAM}")

      if (SERENE_CCACHE_MAXSIZE)
        set(CCACHE_PROGRAM "CCACHE_MAXSIZE=${SERENE_CCACHE_MAXSIZE} ${CCACHE_PROGRAM}")
      endif()
      if (SERENE_CCACHE_DIR)
        set(CCACHE_PROGRAM "CCACHE_DIR=${SERENE_CCACHE_DIR} ${CCACHE_PROGRAM}")
      endif()
      message(STATUS "Using CCACHE: ${CCACHE_PROGRAM}")
      set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_PROGRAM})
    else()
      message(FATAL_ERROR "Unable to find the program ccache. Set SERENE_DISABLE_CCACHE to ON")
    endif()
  endif()

  Include(FetchContent)

  if(SERENE_BUILD_TESTING)
    message(STATUS "Fetching Catch2 v3...")

    FetchContent_Declare(
      Catch2
      GIT_REPOSITORY https://github.com/catchorg/Catch2.git
      GIT_TAG        v3.0.0-preview4
      )
    FetchContent_MakeAvailable(Catch2)
    list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
  endif()

  # LLVM setup ==================================================================
  # Why not specify the version?
  # Since we use the development version of the LLVM all the time it doesn't
  # make sense to use a version here
  find_package(LLVM REQUIRED CONFIG)
  find_package(MLIR REQUIRED CONFIG)
  find_package(LLD REQUIRED CONFIG)
  find_program(LLD_PROGRAM REQUIRED NAMES lld)

  find_program(MLIRTBLGEN_PROGRAM REQUIRED NAMES mlir-tblgen)
  find_package(Clang REQUIRED CONFIG)

  message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
  message(STATUS "Using MLIRConfig.cmake in: ${MLIR_DIR}")
  message(STATUS "Using LLDConfig.cmake in: ${LLD_DIR}")
  message(STATUS "Using CLANGConfig.cmake in: ${Clang_DIR}")

  set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)
  set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/lib)
  set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})

  # Make cmake modules available to load
  list(APPEND CMAKE_MODULE_PATH "${MLIR_DIR}")
  list(APPEND CMAKE_MODULE_PATH "${LLVM_DIR}")
  list(APPEND CMAKE_MODULE_PATH "${LLD_DIR}")
  list(APPEND CMAKE_MODULE_PATH "${Clang_DIR}")

  include(TableGen)
  include(AddLLVM)
  include(AddMLIR)
  include(HandleLLVMOptions)
  include(AddClang)

  # This goes against the CMake's best practices to add
  # these kind of settings to the targets only. But this
  # is what LLVM recommends and we will stick to their
  # recommendation.
  include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
  add_definitions(${LLVM_DEFINITIONS})

  # /LLVM setup =================================================================

  add_subdirectory(serene)
  # include(tablegen-serene)
  # Create the tools we use to compile Serene
  #add_subdirectory(serene-tblgen)
  # The compiled library code is here
  # add_subdirectory(libserene)
  # The static library containing builtin special forms and functions
  # add_subdirectory(core)
  # Binary tools of the compiler
  # add_subdirectory(serenec)
  # add_subdirectory(serene-repl)

  # add_subdirectory(devtools)

  if (SERENE_ENABLE_DOCS)
    add_subdirectory(docs)
  endif()
endif()
