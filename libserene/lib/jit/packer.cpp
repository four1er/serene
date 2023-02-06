/* -*- C++ -*-
 * Serene Programming Language
 *
 * Copyright (c) 2019-2022 Sameer Rahmani <lxsameer@gnu.org>
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

#include "serene/jit/packer.h"

#include "serene/config.h" // for I64_SIZE, COMMON_ARGS_COUNT

#include <llvm/ADT/APInt.h>          // for APInt
#include <llvm/ADT/DenseSet.h>       // for DenseSet
#include <llvm/ADT/STLExtras.h>      // for size, enumerate, enumerator
#include <llvm/ADT/ilist_iterator.h> // for operator!=, ilist_iterator
#include <llvm/ADT/iterator.h>       // for iterator_facade_base
#include <llvm/ADT/iterator_range.h> // for iterator_range
#include <llvm/IR/Argument.h>        // for Argument
#include <llvm/IR/BasicBlock.h>      // for BasicBlock
#include <llvm/IR/Constant.h>        // for Constant
#include <llvm/IR/DerivedTypes.h>    // for PointerType, IntegerType, Funct...
#include <llvm/IR/Function.h>        // for Function
#include <llvm/IR/IRBuilder.h>       // for IRBuilder
#include <llvm/IR/Instructions.h>    // for LoadInst, CallInst
#include <llvm/IR/Module.h>          // for Module
#include <llvm/IR/Type.h>            // for Type
#include <llvm/IR/Value.h>           // for Value
#include <llvm/Support/Casting.h>    // for cast

#include <stdint.h> // for uint64_t
namespace serene::jit {

std::string makePackedFunctionName(llvm::StringRef name) {
  // TODO: move the "_serene_" constant to a macro or something
  return PACKED_FUNCTION_NAME_PREFIX + name.str();
}

void packFunctionArguments(llvm::Module *module) {
  auto &ctx = module->getContext();
  llvm::IRBuilder<> builder(ctx);
  llvm::DenseSet<llvm::Function *> interfaceFunctions;
  for (auto &func : module->getFunctionList()) {
    if (func.isDeclaration()) {
      continue;
    }
    if (interfaceFunctions.count(&func) != 0) {
      continue;
    }

    // Given a function `foo(<...>)`, define the interface function
    // `serene_foo(i8**)`.
    auto *newType = llvm::FunctionType::get(
        builder.getVoidTy(), builder.getInt8PtrTy()->getPointerTo(),
        /*isVarArg=*/false);
    auto newName = makePackedFunctionName(func.getName());
    auto funcCst = module->getOrInsertFunction(newName, newType);
    llvm::Function *interfaceFunc =
        llvm::cast<llvm::Function>(funcCst.getCallee());
    interfaceFunctions.insert(interfaceFunc);

    // Extract the arguments from the type-erased argument list and cast them to
    // the proper types.
    auto *bb = llvm::BasicBlock::Create(ctx);
    bb->insertInto(interfaceFunc);
    builder.SetInsertPoint(bb);
    llvm::Value *argList = interfaceFunc->arg_begin();
    llvm::SmallVector<llvm::Value *, COMMON_ARGS_COUNT> args;

    args.reserve(static_cast<unsigned long>(llvm::size(func.args())));
    for (const auto &indexedArg : llvm::enumerate(func.args())) {
      llvm::Value *argIndex = llvm::Constant::getIntegerValue(
          builder.getInt64Ty(), llvm::APInt(I64_SIZE, indexedArg.index()));
      llvm::Value *argPtrPtr =
          builder.CreateGEP(builder.getInt8PtrTy(), argList, argIndex);
      llvm::Value *argPtr =
          builder.CreateLoad(builder.getInt8PtrTy(), argPtrPtr);
      llvm::Type *argTy = indexedArg.value().getType();
      argPtr            = builder.CreateBitCast(argPtr, argTy->getPointerTo());
      llvm::Value *arg  = builder.CreateLoad(argTy, argPtr);
      args.push_back(arg);
    }

    // Call the implementation function with the extracted arguments.
    llvm::Value *result = builder.CreateCall(&func, args);

    // Assuming the result is one value, potentially of type `void`.
    if (!result->getType()->isVoidTy()) {
      llvm::Value *retIndex = llvm::Constant::getIntegerValue(
          builder.getInt64Ty(),
          llvm::APInt(I64_SIZE,
                      static_cast<uint64_t>(llvm::size(func.args()))));
      llvm::Value *retPtrPtr =
          builder.CreateGEP(builder.getInt8PtrTy(), argList, retIndex);
      llvm::Value *retPtr =
          builder.CreateLoad(builder.getInt8PtrTy(), retPtrPtr);
      retPtr = builder.CreateBitCast(retPtr, result->getType()->getPointerTo());
      builder.CreateStore(result, retPtr);
    }

    // The interface function returns void.
    builder.CreateRetVoid();
  }
};

} // namespace serene::jit
