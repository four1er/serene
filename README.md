# Serene lang
[![status-badge](https://ci.devheroes.codes/api/badges/Serene/serene/status.svg)](https://ci.devheroes.codes/Serene/serene)

Serene is a modern typed lisp. It's not done yet, and it's heavily under development.

## Dependencies
Here is the list of dependencies that need to be present:
- LLVM (You can find the exact version in the `builder` script)
- CMake `>= 3.19`
- Ninja
- include-what-you-use
- Valgrind (Optional and only for development)
- CCache (If you want faster builds, specially with the LLVM)
- Boehm GC v8.2.2
  make sure to build in statically with `-fPIC` flag.
- zstd (Only if you want to use prebuilt dependencies on Linux)
- Musl libc v1.2.3 (It's not required but highly recommended)
- libc++ (same version as LLVM abviously. It's not required but highly recommended)
- compiler-rt (same version as LLVM abviously. It's not required but highly recommended)

If you are using Linux (x86_64 only), then you're in luck. The `builder` script
will download the required toolchain automatically for you and set it up. So,
you can just use `builder` subcommands to develop serene.

You can disable this behaviour by setting the `USE_SERENE_TOOLCHAIN` env variable to
anything beside "true".

Serene build system uses Musl, libc++, and compiler-rt to generate a static binary.
You can use glibc, libgcc, and libstdc++ instead. But you might not be able to
cross compiler with Serene and also if anything happen to you, I might not be able
to help (I'll try for sure).

## Setup development environment
Before, you have to set up the necessary git hooks as follows:

```bash
 ./builder setup
```

** Build and installing dependencies (Other platforms)
Currently, the `builder` script does not support any platform beside GNU/Linux. So, you
need to build the dependencies yourself and make them available to the builder.

By the way, If you are interested, you can just hack the builder script and accommodate your
platform and contribute your changes to the project.

To build the dependencies in your platform, you can use the https://devheroes.codes/Serene/bootstrap-toolchain
repo as a reference or even modify it to support other platforms. Any contribution will be appreciated.

# How to build
To build for development (Debug mode) just use `./builder build` to setup the build system,
and build the project once, and then you can just use `./builder compile` to build the changed files
only.

Check out the `builder` script for more subcommands and details.

# How to Debug
Since we're using the Boehm GC, to use a debugger, we need to turn off some of the signal
handlers that the debugger sets. To run the debugger (by default, lldb) with `serenec`
just use the `lldb-run` subcommand of the builder script. In the debugger, after setting the
break point on the `main` function (`b main`) then use the following commands on:

```
process handle -p yes -s no -n no SIGPWR
process handle -p yes -s no -n no SIGXCPU
process handle -p yes -s no -n no SIGSEGV
```

# Cheatsheets
- (Modern C++ Cheatsheet)[https://github.com/muqsitnawaz/modern-cpp-cheatsheet]

# More Info
- Website: https://serene-lang.org
- CI: https://ci.devheroes.codes/Serene/serene

# Get Help
If you need help, or you just want to hang out, you can find us at:

- *IRC*: *#serene-lang* on the libera chat server
- *Matrix*: https://app.element.io/#/room/#serene:matrix.org
- *MailingList*: https://www.freelists.org/list/serene

# License
Copyright (c) 2019-2023 Sameer Rahmani <lxsameer@gnu.org>

*Serene* is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 2.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
