/*
 * Serene programming language.
 *
 *  Copyright (c) 2019-2021 Sameer Rahmani <lxsameer@gnu.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "serene/exprs/list.h"
#include "serene/exprs/def.h"
#include "serene/exprs/symbol.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormatVariadic.h"
#include <iterator>

namespace serene {
namespace exprs {

List::List(const List &l) : Expression(l.location){};
List::List(const reader::LocationRange &loc, node &e) : Expression(loc) {
  elements.push_back(e);
};

List::List(const reader::LocationRange &loc, ast elems)
    : Expression(loc), elements(elems){};

ExprType List::getType() const { return ExprType::List; };
std::string List::toString() const {
  std::string s{this->elements.empty() ? "-" : ""};

  for (auto &n : this->elements) {
    s = llvm::formatv("{0} {1}", s, n->toString());
  }

  return llvm::formatv("<List [loc: {0} | {1}]: {2}>",
                       this->location.start.toString(),
                       this->location.end.toString(), s);
};

maybe_node List::analyze(reader::SemanticContext &ctx) {
  if (!elements.empty()) {
    auto *first = elements[0].get();

    if (first->getType() == ExprType::Symbol) {
      auto *sym = llvm::dyn_cast<Symbol>(first);

      if (sym) {
        if (sym->name == "def") {
          if (auto err = Def::isValid(this)) {
            // Not a valid `def` form
            return Result<node>::error(std::move(err));
          }

          Symbol *binding = llvm::dyn_cast<Symbol>(elements[1].get());

          if (!binding) {
            llvm_unreachable("Def::isValid should of catch this.");
          }

          node def = make<Def>(location, binding->name, elements[2]);
          return Result<node>::success(def);
        }
      }

      // TODO: Return an error saying the binding has to be
      //       a symbol
    }
  }

  return Result<node>::success(nullptr);
};

bool List::classof(const Expression *e) {
  return e->getType() == ExprType::List;
};

/// Return an iterator to be used with the `for` loop. It's implicitly called by
/// the for loop.
std::vector<node>::const_iterator List::cbegin() { return elements.begin(); }

/// Return an iterator to be used with the `for` loop. It's implicitly called by
/// the for loop.
std::vector<node>::const_iterator List::cend() { return elements.end(); }

/// Return an iterator to be used with the `for` loop. It's implicitly called by
/// the for loop.
std::vector<node>::iterator List::begin() { return elements.begin(); }

/// Return an iterator to be used with the `for` loop. It's implicitly called by
/// the for loop.
std::vector<node>::iterator List::end() { return elements.end(); }

size_t List::count() const { return elements.size(); }

llvm::Optional<Expression *> List::at(uint index) {
  if (index >= elements.size()) {
    return llvm::None;
  }

  return llvm::Optional<Expression *>(this->elements[index].get());
}

void List::append(node n) { elements.push_back(std::move(n)); }
} // namespace exprs
} // namespace serene
