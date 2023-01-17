//
//  ValueBinder+Binding.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

// MARK: - Value Binding

extension ValueBinder {
	// A binding object that stores an object and a callback for a valuebinder
	class Binding {
		// Is the registering object still alive?
		@inline(__always) var isAlive: Bool { return object != nil }

		// A weakly held registration object to keep track of the lifetimes of the change block
		weak var object: AnyObject?

		// Callback for when the value changes
		private var changeBlock: ((ValueType) -> Void)?

		// Create a binding
		init(_ object: AnyObject, _ changeBlock: @escaping (ValueType) -> Void) {
			self.object = object
			self.changeBlock = changeBlock
		}

		// Deregister this binder to stop it receiving change notifications
		func deregister() {
			self.object = nil
			self.changeBlock = nil
		}

		// Called when the wrapped value changes. Propagate the new value through the changeblock
		func didChange(_ value: ValueType) -> Bool {
			if object != nil, let callback = changeBlock {
				callback(value)
				return true
			}
			else {
				self.deregister()
				return false
			}
		}
	}
}
