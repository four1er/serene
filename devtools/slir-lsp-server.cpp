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

#include "serene/slir/dialect.h"

#include <mlir/Dialect/Func/IR/FuncOps.h>
#include <mlir/IR/Dialect.h>
#include <mlir/Tools/mlir-lsp-server/MlirLspServerMain.h>

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;

  serene::slir::registerTo(registry);

  registry.insert<mlir::func::FuncDialect>();

  // TODO: Register passes here
  return static_cast<int>(
      mlir::failed(mlir::MlirLspServerMain(argc, argv, registry)));
}
