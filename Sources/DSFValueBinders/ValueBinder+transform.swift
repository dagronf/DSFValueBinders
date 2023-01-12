//
//  ValueBinder+transform.swift
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

public extension ValueBinder {
	/// Returns a new value binder which returns a transformed value from this binder
	func transform<NEWBINDERTYPE>(
		_ block: @escaping (ValueBinder<ValueType>) -> NEWBINDERTYPE
	) -> ValueBinder<NEWBINDERTYPE> {

		let initialValue = block(self)

		// Create the binder
		let newBinder = ValueBinder<NEWBINDERTYPE>(initialValue)

		self.register { [weak self] newValue in
			guard let `self` = self else { return }
			newBinder.wrappedValue = block(self)
		}
		return newBinder
	}
}

public extension ValueBinder where ValueType == Bool {
	/// Returns a value binder which returns a toggled version of this valuebinder's wrapped bool value
	func toggled() -> ValueBinder<Bool> {
		let negated = ValueBinder(!self.wrappedValue)
		self.register { newValue in
			negated.wrappedValue = !newValue
		}
		return negated
	}

	/// Returns a value binder which returns a toggled version of this valuebinder's wrapped bool value
//	func toggled() -> ValueBinder<Bool> {
//		self.transform { origBinder in
//			!origBinder.wrappedValue
//		}
//	}
}
