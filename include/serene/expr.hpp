/**
 * Serene programming language.
 *
 *  Copyright (c) 2020 Sameer Rahmani <lxsameer@gnu.org>
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

#ifndef EXPR_H
#define EXPR_H

#include "serene/logger.hpp"
#include "serene/reader/location.h"
#include <string>

#if defined(ENABLE_LOG) || defined(ENABLE_EXPR_LOG)
#define EXPR_LOG(...) __LOG("EXPR", __VA_ARGS__);
#else
#define EXPR_LOG(...) ;
#endif

namespace serene {

enum class SereneType {
  Expression,
  Symbol,
  List,
  Error,
  Number,
};

class AExpr {
public:
  std::unique_ptr<reader::LocationRange> location;

  virtual ~AExpr() = default;

  virtual SereneType getType() const = 0;
  virtual std::string string_repr() const = 0;
  virtual std::string dumpAST() const = 0;
};

using ast_node = std::shared_ptr<AExpr>;
using ast_tree = std::vector<ast_node>;

} // namespace serene

#endif