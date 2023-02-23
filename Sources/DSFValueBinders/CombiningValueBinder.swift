//
//  CombiningValueBinder.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import Foundation

/// A ValueBinder whose output is the result combining the outputs of multiple ValueBinders
public class CombiningValueBuilder<ResultType>: ValueBinder<ResultType> {
	/// Create a ValueBinder that is a combination of the values of two different ValueBinders
	/// - Parameters:
	///   - v1: The first valuebinder
	///   - v2: The second valuebinder
	///   - block: The block to call when the valuebinders change to retrieve the updated value
	public init<T1, T2>(
		_ v1: ValueBinder<T1>,
		_ v2: ValueBinder<T2>,
		_ block: @escaping (T1, T2) -> ResultType
	) {
		super.init(block(v1.wrappedValue, v2.wrappedValue))
		v1.register(self) { [weak self, weak v2] newValue in
			guard let `self` = self, let v2Value = v2?.wrappedValue else { return }
			self.wrappedValue = block(newValue, v2Value)
		}
		v2.register(self) { [weak self, weak v1] newValue in
			guard let `self` = self, let v1Value = v1?.wrappedValue else { return }
			self.wrappedValue = block(v1Value, newValue)
		}
	}

	/// Create a ValueBinder that is a combination of the values of three different ValueBinders
	/// - Parameters:
	///   - v1: The first valuebinder
	///   - v2: The second valuebinder
	///   - v3: The third valuebinder
	///   - block: The block to call when the valuebinders change to retrieve the updated value
	public init<T1, T2, T3>(
		_ v1: ValueBinder<T1>,
		_ v2: ValueBinder<T2>,
		_ v3: ValueBinder<T3>,
		_ block: @escaping (T1, T2, T3) -> ResultType
	) {
		super.init(block(v1.wrappedValue, v2.wrappedValue, v3.wrappedValue))
		v1.register(self) { [weak self, weak v2, weak v3] newValue in
			guard
				let `self` = self,
					let v2Value = v2?.wrappedValue,
					let v3Value = v3?.wrappedValue
			else {
				return
			}
			self.wrappedValue = block(newValue, v2Value, v3Value)
		}
		v2.register(self) { [weak self, weak v1, weak v3] newValue in
			guard
				let `self` = self,
					let v1Value = v1?.wrappedValue,
					let v3Value = v3?.wrappedValue
			else {
				return
			}
			self.wrappedValue = block(v1Value, newValue, v3Value)
		}
		v3.register(self) { [weak self, weak v1, weak v2] newValue in
			guard
				let `self` = self,
				let v1Value = v1?.wrappedValue,
				let v2Value = v2?.wrappedValue
			else {
				return
			}
			self.wrappedValue = block(v1Value, v2Value, newValue)
		}
	}

	deinit {
		Swift.print("\(self): deinit")
	}
}
