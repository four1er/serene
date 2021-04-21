/* -*- C++ -*-
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

#ifndef SERENE_ERRORS_CONSTANTS_H
#define SERENE_ERRORS_CONSTANTS_H

#include <map>
#include <string>

namespace serene {
namespace errors {

enum ErrID {
  E0000,
  E0001,

};

struct ErrorVariant {
  ErrID id;
  std::string description;
  std::string longDescription;

  ErrorVariant(ErrID id, std::string desc, std::string longDesc)
      : id(id), description(desc), longDescription(longDesc){};
};

static ErrorVariant
    UnknownError(E0000, "Can't find any description for this error.", "");
static ErrorVariant
    DefExpectSymbol(E0001, "The first argument to 'def' has to be a Symbol.",
                    "");

static std::map<ErrID, ErrorVariant *> ErrDesc = {{E0000, &UnknownError},
                                                  {E0001, &DefExpectSymbol}};

} // namespace errors
} // namespace serene
#endif
