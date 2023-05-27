---
title: Getting Started
---

# Getting Started
Serene is under heavy development. This guide is dedicated to help you to get started with
Serene development.

This guide assumes that you are familiar with C/C++ development and ecosystem.

## Are you a Linux user?
If you are using Linux (x86_64 only), then you're in luck. The `builder` script
will download the required toolchain automatically for you and set it up. So,
you can just use `builder` subcommands to develop serene (you still need to
install `cmake` and `ninja`).

You can disable this behaviour by setting the `USE_SERENE_TOOLCHAIN` env variable to
anything beside "true".

## Dependencies
Here is the list of dependencies that need to be present:
- `LLVM` (You can find the exact version in the `builder` script)
- `CMake` `>= 3.19`
- `Ninja`
- `include-what-you-use`
- `Valgrind` (Optional and only for development)
- `CCache` (If you want faster builds, specially with the LLVM)
- `Boehm GC` `v8.2.2`
  make sure to build in statically with `-fPIC` flag.
- `zstd` (Only if you want to use prebuilt dependencies on Linux)
- Musl libc `v1.2.3` (It's not required but highly recommended)
- `libc++` (same version as LLVM abviously. It's not required but highly recommended)
- `compiler-rt` (same version as LLVM abviously. It's not required but highly recommended)

Serene build system uses Musl, libc++, and compiler-rt to generate a static binary.
You can use glibc, libgcc, and libstdc++ instead. But you might not be able to
cross compiler with Serene and also if anything happen to you, I might not be able
to help (I'll try for sure).

## Setup development environment
Before, you have to set up the necessary git hooks as follows:

```bash
 ./builder setup
```

## Build and installing dependencies (Other platforms)
Currently, the `builder` script does not support any platform beside GNU/Linux. So, you
need to build the dependencies yourself and make them available to the builder.

By the way, If you are interested, you can just hack the builder script and accommodate your
platform and contribute your changes to the project.

To build the dependencies in your platform, you can use the https://devheroes.codes/Serene/bootstrap-toolchain
repo as a reference or even modify it to support other platforms. Any contribution will be appreciated.

After all, it's just a cmake project. So, don't be afraid.

## How to build
To build for development (Debug mode) just use `./builder build` to setup the build system,
and build the project once, and then you can just use `./builder compile` to build the changed files
only.

Check out the `builder` script for more subcommands and details.

## How to debug
Since we're using the Boehm GC, to use a debugger, we need to turn off some of the signal
handlers that the debugger sets. To run the debugger (by default, lldb) with `serene`
just use the `lldb-run` subcommand of the builder script. In the debugger, after setting the
break point on the `main` function (`b main`) then use the following commands on:

```
process handle -p yes -s no -n no SIGPWR
process handle -p yes -s no -n no SIGXCPU
process handle -p yes -s no -n no SIGSEGV
```

## Cheatsheets
- [Modern C++ Cheatsheet](https://github.com/muqsitnawaz/modern-cpp-cheatsheet)
- [Modern CMake](https://cliutils.gitlab.io/modern-cmake/)
