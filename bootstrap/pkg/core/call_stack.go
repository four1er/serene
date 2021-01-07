/*
 Serene --- Yet an other Lisp

Copyright (c) 2020  Sameer Rahmani <lxsameer@gnu.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

package core

// CallStack implementation:
// * A callstack should be FIFA stack
// * It should keep track of function calls.
// * Anything that implements `IFn` can be tracked by the call stack
// * Since Serene uses eval loop to eliminate tail calls we need
// the call stack to be able to track recursive calls. For
// now by just counting number of calls to a functions that is already
// in the stack.
//
// TODOs:
// * At the moment if we call the same function twice (not as a recursive)
//   function call stack will record it as a recursive call. We need
//   compare the stack items by their address, identity and location.
// * Add support for iteration on the stack.

import (
	"fmt"
)

type ICallStack interface {
	// Push the given callable `f` to the stack
	Push(f IFn) IError
	Pop() *Frame
	Peek() *Frame
	Count() uint
}

type Frame struct {
	// Number of recursive calls to this function
	Count  uint
	Fn     IFn
	Caller IExpr
}

type TraceBack = []*Frame

type CallStackItem struct {
	prev *CallStackItem
	data Frame
}

type CallStack struct {
	debug bool
	head  *CallStackItem
	count uint
}

func (f *Frame) String() string {
	return fmt.Sprintf("<Frame: FN: %s, Count: %d Caller: \n%s\n>", f.Fn, f.Count, f.Caller)
}

func (c *CallStack) Count() uint {
	return c.count
}

func (c *CallStack) GetCurrentFn() IFn {
	if c.head == nil {
		return nil
	}

	return c.head.data.Fn
}

func (c *CallStack) Push(caller IExpr, f IFn) IError {
	if c.debug {
		fmt.Println("[Stack] -->", f)
	}

	if f == nil {
		return MakePlainError("Can't push 'nil' pointer to the call stack.")
	}

	if caller == nil {
		return MakePlainError("Can't push 'nil' pointer to the call stack for the caller.")
	}

	// Empty Stack
	if c.head == nil {
		c.head = &CallStackItem{
			data: Frame{
				Fn:     f,
				Caller: caller,
				Count:  0,
			},
		}
		c.count++
	}

	nodeData := &c.head.data

	// If the same function was on top of the stack
	if nodeData.Fn == f && caller == nodeData.Caller {
		// TODO: expand the check here to support address and location as well
		nodeData.Count++
	} else {
		c.head = &CallStackItem{
			prev: c.head,
			data: Frame{
				Fn:     f,
				Caller: caller,
				Count:  0,
			},
		}
		c.count++
	}
	return nil
}

func (c *CallStack) Pop() *Frame {
	if c.head == nil {
		if c.debug {
			fmt.Println("[Stack] <-- nil")
		}
		return nil
	}

	result := c.head
	c.head = result.prev
	c.count--
	if c.debug {
		fmt.Printf("[Stack] <-- %s\n", result.data.Fn)
	}
	return &result.data
}

func (c *CallStack) Peek() *Frame {
	if c.head == nil {
		if c.debug {
			fmt.Println("[Stack] <-- nil")
		}
		return nil
	}

	result := c.head
	return &result.data
}

func (c *CallStack) ToTraceBack() *TraceBack {
	var tr TraceBack
	item := c.head
	for {
		if item == nil {
			break
		}
		// TODO: This doesn't seem efficient. Fix it.
		tr = append([]*Frame{&item.data}, tr...)
		item = item.prev
	}

	return &tr
}

func MakeCallStack(debugMode bool) CallStack {
	return CallStack{
		count: 0,
		head:  nil,
		debug: debugMode,
	}
}

func MakeFrame(caller IExpr, f IFn, count uint) *Frame {
	return &Frame{
		Count:  count,
		Caller: caller,
		Fn:     f,
	}
}
