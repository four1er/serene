/** Serene --- Yet an other Lisp
*
* Copyright (c) 2020  Sameer Rahmani <lxsameer@gnu.org>
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
use crate::compiler::Compiler;
use inkwell::values::{AnyValue, AnyValueEnum};

type ExprResultBase<'a, T: AnyValue<'a>> = Result<T, String>;

pub type ExprResult<'a> = ExprResultBase<'a, AnyValueEnum<'a>>;

pub trait Expression {
    fn eval();
    fn code_gen<'ctx, 'val: 'ctx>(&self, compiler: &'ctx mut Compiler<'val>) -> ExprResult<'val>;
}