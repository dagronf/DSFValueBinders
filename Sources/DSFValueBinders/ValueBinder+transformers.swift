//
//  ValueBinder+transformers.swift
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

// Some built-in ValueBinder transforms

import Foundation

// MARK: - Bool transforms

public extension ValueBinder where ValueType == Bool {
	/// Returns a value binder which returns a toggled version of this valuebinder's wrapped bool value
	func toggled() -> ValueBinder<Bool> {
		self.transform { !$0 }
	}
}

// MARK: - Numeric transforms

public extension ValueBinder where ValueType: Numeric {
	/// A number to string conversion transform
	/// - Parameters:
	///   - formatter: An optional numberformatter to format the value
	///   - nilValue: The string to display if the formatter cannot generate a formatted string
	/// - Returns:
	func stringValue(using formatter: NumberFormatter? = nil, nilValue: String = "<empty>") -> ValueBinder<String> {
		if let formatter = formatter {
			return self.transform { newValue in
				formatter.string(for: newValue) ?? nilValue
			}
		}
		else {
			// Use Swift's description value for the output
			return self.transform { "\($0)" }
		}
	}
}

public extension ValueBinder where ValueType: BinaryFloatingPoint {
	/// Get an integer represetation of the double/float value using a specified rounding rule
	func intValue(rule: FloatingPointRoundingRule = .towardZero) -> ValueBinder<Int> {
		self.transform { Int($0.rounded(rule)) }
	}
}

public extension ValueBinder where ValueType == Double? {
	/// Create a value binder with a default value when the value is nil
	/// - Parameter defaultValue: The default value to return with the value is nil
	/// - Returns: A new ValueBinder
	func unwrappingValue(usingDefault defaultValue: Double) -> ValueBinder<Double> {
		self.transform { $0 ?? defaultValue }
	}
}

public extension ValueBinder where ValueType == Int? {
	/// Create a value binder with a default value when the value is nil
	/// - Parameter defaultValue: The default value to return with the value is nil
	/// - Returns: A new ValueBinder
	func unwrappingValue(usingDefault defaultValue: Int) -> ValueBinder<Int> {
		self.transform { $0 ?? defaultValue }
	}
}

public extension ValueBinder where ValueType: BinaryInteger {
	/// A simple transformer that returns a ValueBinder that presents the words representation for an int
	func asWords(locale: Locale? = nil) -> ValueBinder<String> {
		self.transform { newValue in
			let nf = NumberFormatter()
			nf.numberStyle = .spellOut
			if let locale = locale {
				nf.locale = locale
			}
			return nf.string(for: newValue) ?? ""
		}
	}
}

// MARK: - URL transforms

public extension ValueBinder where ValueType == URL {
	/// A transformer that converts a fileURL to a filePath
	func filePath() -> ValueBinder<String> {
		self.transform { $0.path }
	}
}

// MARK: - String transforms

public extension ValueBinder where ValueType == String {
	/// A transform that provides a placeholder string IF the input string is empty
	func stringValue(emptyPlaceholderString: String) -> ValueBinder<String> {
		self.transform { text in
			text.isEmpty ? emptyPlaceholderString : text
		}
	}
}

public extension ValueBinder where ValueType == String? {
	/// A transform that provides a placeholder string IF the input string is nil
	func unwrappingValue(usingDefault defaultValue: String) -> ValueBinder<String> {
		self.transform { $0 ?? defaultValue }
	}

	/// A transform that provides a placeholder string IF the input string is nil or empty
	func stringValue(emptyPlaceholderString: String) -> ValueBinder<String> {
		self.transform { text in
			if let text = text, text.isEmpty == false {
				return text
			}
			return emptyPlaceholderString
		}
	}
}
