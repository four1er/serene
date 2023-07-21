/* -*- C++ -*-
 * Serene Programming Language
 *
 * Copyright (c) 2019-2023 Sameer Rahmani <lxsameer@gnu.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CONTEXT_H
#define CONTEXT_H

#include "options.h"             // for Options
#include <__fwd/string.h>        // for string
#include <__memory/unique_ptr.h> // for make_unique, unique_ptr

#include <llvm/ADT/Twine.h>           // for Twine
#include <llvm/IR/LLVMContext.h>      // for LLVMContext
#include <llvm/TargetParser/Host.h>   // for getDefaultTargetTriple
#include <llvm/TargetParser/Triple.h> // for Triple

#include <string> // for basic_string
#include <vector> // for vector

namespace serene {
class SereneContext;

/// This enum describes the different operational phases for the compiler
/// in order. Anything below `NoOptimization` is considered only for debugging
enum class CompilationPhase {
  Parse,
  Analysis,
  SLIR,
  MLIR, // Lowered slir to other dialects
  LIR,  // Lowered to the llvm ir dialect
  IR,   // Lowered to the LLVMIR itself
  NoOptimization,
  O1,
  O2,
  O3,
};

/// Terminates the serene compiler process in a thread safe manner
/// This function is only meant to be used in the compiler context
/// if you want to terminate the process in context of a serene program
/// via the JIT use an appropriate function in the `serene.core` ns.
void terminate(SereneContext &ctx, int exitCode);

// Why SereneContext and not Context? We will be using LLVMContext
// and MLIRContext through out Serene, so it's better to follow
// the same convention
class SereneContext {

public:
  /// The set of options to change the compilers behaviors
  Options options;

  const llvm::Triple triple;

  explicit SereneContext(Options &options)
      : options(options), triple(llvm::sys::getDefaultTargetTriple()),
        targetPhase(CompilationPhase::NoOptimization){};

  /// Set the target compilation phase of the compiler. The compilation
  /// phase dictates the behavior and the output type of the compiler.
  void setOperationPhase(CompilationPhase phase);

  CompilationPhase getTargetPhase() { return targetPhase; };
  int getOptimizatioLevel();

  static std::unique_ptr<llvm::LLVMContext> genLLVMContext() {
    return std::make_unique<llvm::LLVMContext>();
  };

  /// Setup the load path for namespace lookups
  void setLoadPaths(std::vector<std::string> &dirs) { loadPaths.swap(dirs); };

  /// Return the load paths for namespaces
  std::vector<std::string> &getLoadPaths() { return loadPaths; };

private:
  CompilationPhase targetPhase;
  std::vector<std::string> loadPaths;
};

/// Creates a new context object. Contexts are used through out the compilation
/// process to store the state.
///
/// \p opts is an instance of \c Options that can be used to set options of
///         of the compiler.
std::unique_ptr<SereneContext> makeSereneContext(Options opts = Options());

} // namespace serene

#endif
