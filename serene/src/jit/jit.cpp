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

#include "jit/jit.h"

#include "options.h"    // for Options
#include <system_error> // for error_code

#include <llvm/ADT/StringMapEntry.h>               // for StringMapEntry
#include <llvm/ADT/iterator.h>                     // for iterator_facade_base
#include <llvm/ExecutionEngine/JITEventListener.h> // for JITEventListener
#include <llvm/ExecutionEngine/Orc/LLJIT.h>        // IWYU pragma: keep
#include <llvm/IR/Module.h>                        // for Module
#include <llvm/Support/FileSystem.h>               // for OpenFlags
#include <llvm/Support/ToolOutputFile.h>           // for ToolOutputFile

#include <assert.h> // for assert
#include <string>   // for operator+, char_t...

namespace serene::jit {

// ----------------------------------------------------------------------------
// ObjectCache Implementation
// ----------------------------------------------------------------------------
void ObjectCache::notifyObjectCompiled(const llvm::Module *m,
                                       llvm::MemoryBufferRef objBuffer) {
  cachedObjects[m->getModuleIdentifier()] =
      llvm::MemoryBuffer::getMemBufferCopy(objBuffer.getBuffer(),
                                           objBuffer.getBufferIdentifier());
}

std::unique_ptr<llvm::MemoryBuffer>
ObjectCache::getObject(const llvm::Module *m) {
  auto i = cachedObjects.find(m->getModuleIdentifier());

  if (i == cachedObjects.end()) {
    HALLEY_LOG("No object for " + m->getModuleIdentifier() +
               " in cache. Compiling.");
    return nullptr;
  }

  HALLEY_LOG("Object for " + m->getModuleIdentifier() + " loaded from cache.");
  return llvm::MemoryBuffer::getMemBuffer(i->second->getMemBufferRef());
}

void ObjectCache::dumpToObjectFile(llvm::StringRef outputFilename) {
  // Set up the output file.
  std::error_code error;

  auto file = std::make_unique<llvm::ToolOutputFile>(outputFilename, error,
                                                     llvm::sys::fs::OF_None);
  if (error) {

    llvm::errs() << "cannot open output file '" + outputFilename.str() +
                        "': " + error.message()
                 << "\n";
    return;
  }
  // Dump the object generated for a single module to the output file.
  // TODO: Replace this with a runtime check
  assert(cachedObjects.size() == 1 && "Expected only one object entry.");

  auto &cachedObject = cachedObjects.begin()->second;
  file->os() << cachedObject->getBuffer();
  file->keep();
}

// ----------------------------------------------------------------------------
// JIT Implementation
// ----------------------------------------------------------------------------
orc::JITDylib *JIT::getLatestJITDylib(const llvm::StringRef &nsName) {
  if (jitDylibs.count(nsName) == 0) {
    return nullptr;
  }

  auto vec = jitDylibs[nsName];
  // TODO: Make sure that the returning Dylib still exists in the JIT
  //       by calling jit->engine->getJITDylibByName(dylib_name);
  return vec.empty() ? nullptr : vec.back();
};

void JIT::pushJITDylib(const llvm::StringRef &nsName, llvm::orc::JITDylib *l) {
  if (jitDylibs.count(nsName) == 0) {
    llvm::SmallVector<llvm::orc::JITDylib *, 1> vec{l};
    jitDylibs[nsName] = vec;
    return;
  }
  auto vec = jitDylibs[nsName];
  vec.push_back(l);
  jitDylibs[nsName] = vec;
}

size_t JIT::getNumberOfJITDylibs(const llvm::StringRef &nsName) {
  if (jitDylibs.count(nsName) == 0) {
    return 0;
  }

  return jitDylibs[nsName].size();
};

JIT::JIT(llvm::orc::JITTargetMachineBuilder &&jtmb, Options &opts)
    : isLazy(opts.JITLazy),
      cache(opts.JITenableObjectCache ? new ObjectCache() : nullptr),
      gdbListener(opts.JITenableGDBNotificationListener
                      ? llvm::JITEventListener::createGDBRegistrationListener()
                      : nullptr),
      perfListener(opts.JITenablePerfNotificationListener
                       ? llvm::JITEventListener::createPerfJITEventListener()
                       : nullptr),
      jtmb(jtmb){};

} // namespace serene::jit
