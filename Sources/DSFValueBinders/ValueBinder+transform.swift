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
	/// - Parameter block: A block which transforms this binder's value to a new value
	/// - Returns: A new ValueBinder
	func transform<NEWBINDERTYPE>(
		_ block: @escaping (ValueType) -> NEWBINDERTYPE
	) -> ValueBinder<NEWBINDERTYPE> {
		// Grab out the current value of this binder, and transform it using the block
		let initialValue = block(self.wrappedValue)

		// Create the binder
		let newBinder = ValueBinder<NEWBINDERTYPE>(initialValue)

		self.register { newValue in
			// guard let `self` = self else { return }
			newBinder.wrappedValue = block(newValue)
		}
		return newBinder
	}
}

// MARK: - Transform examples

public extension ValueBinder where ValueType == Bool {
	/// Returns a value binder which returns a toggled version of this valuebinder's wrapped bool value
	func toggled() -> ValueBinder<Bool> {
		self.transform { !$0 }
	}
}

public extension ValueBinder where ValueType: ExpressibleByIntegerLiteral {
	/// A basic Int/Double etc. to String conversion
	func stringValue() -> ValueBinder<String> {
		self.transform { "\($0)" }
	}
}

public extension ValueBinder where ValueType == Double {
	/// Get an integer represetation of the double value
	func intValue(rule: FloatingPointRoundingRule = .towardZero) -> ValueBinder<Int> {
		self.transform { Int($0.rounded(rule)) }
	}
}

public extension ValueBinder where ValueType == Float {
	/// Get an integer represetation of the float value
	func intValue(rule: FloatingPointRoundingRule = .towardZero) -> ValueBinder<Int> {
		self.transform { Int($0.rounded(rule)) }
	}
}

public extension ValueBinder where ValueType == Int {
	/// A simple transformer that returns a ValueBinder that presents the words representation for an int
	func asWords(locale: Locale? = nil) -> ValueBinder<String> {
		self.transform { newValue in
			let nf = NumberFormatter()
			nf.numberStyle = .spellOut
			if let locale = locale {
				nf.locale = locale
			}
			return nf.string(from: NSNumber(value: newValue)) ?? ""
		}
	}
}
