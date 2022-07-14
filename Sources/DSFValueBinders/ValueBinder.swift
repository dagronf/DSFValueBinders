//
//  ValueBinder.swift
//
//  Copyright © 2022 Darren Ford. All rights reserved.
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
import os

#if canImport(Combine)
import Combine
#endif

// MARK: - ValueBinder

/// A wrapped value binder for sharing dynamic values between elements
public class ValueBinder<ValueType: Any> {
	/// An identifier for the binder for use when debugging
	public let identifier: String

	/// The wrapped value to be bound against
	public var wrappedValue: ValueType {
		didSet {
			self.valueDidChange()
		}
	}

	/// Called when the wrappedValue is updated.
	///
	/// Can be overridden by inherited classes, but `super.valueDidChange()` MUST be called first in the override
	open func valueDidChange() {
		let value = self.wrappedValue

		var hasInactiveBindings = false

		self.bindings.forEach { binding in
			if binding.didChange(value) == false {
				hasInactiveBindings = true
			}
		}

		if hasInactiveBindings {
			self.cleanupInactiveBindings()
		}

		// Update the publisher value for combine. Does nothing for < 10.15
		if #available(macOS 10.15, iOS 13, tvOS 13, *) {
			self.publisher?.send(value)
		}
	}

	/// A combine publisher for the binding. If Combine isn't available, will be nil
	///
	/// ```
	/// let cancellable = binder.publisher?.sink { newValue in
	///    // do something with newValue
	/// }
	/// ```
	public private(set) lazy var publisher = WrappedPublisher<ValueType>()

	/// Create a bound value
	///
	/// - Parameters:
	///   - value: The initial value for the binding
	///   - identifier: An identifying string (mainly used for debugging)
	///   - changeCallback: (optional) A callback block to call when the value changes
	///
	/// Example usage:
	/// ```swift
	/// let firstNameBinder = ValueBinder("") { newValue in
	///    Swift.print("firstName changed to '\(newValue)'")
	/// }
	/// let ageBinder = ValueBinder(21) { newValue in
	///    Swift.print("age changed to '\(newValue)'")
	/// }
	/// ```
	public init(_ value: ValueType, _ identifier: String = "", _ changeCallback: ((ValueType) -> Void)? = nil) {
		self.identifier = identifier
		self.wrappedValue = value

		// If a callback is requested, then set ourselves up as a binding too
		if let callback = changeCallback {
			self.register(self, callback)
		}
	}

	deinit {
		if #available(macOS 10.12, *) {
			os_log("%@ [%@] deinit", log: .default, type: .debug, selfTypeString, identifier)
		}
		else {
			// Fallback on earlier versions
		}
		self.deregisterAll()
	}

	// MARK: Private

	/// Returns the number of active registered bindings
	public var activeBindingCount: Int { self.bindings.filter { $0.isAlive }.count }
	/// Returns the total number of registered bindings, including those which are no longer active
	public var totalBindingCount: Int { self.bindings.count }

	// The object that are binding to the value of this object
	private var bindings = [Binding]()
	// A string representation of the object (used for logging)
	private lazy var selfTypeString = "\(type(of: self))"
}

// MARK: - Register/Deregister

public extension ValueBinder {
	/// Register a listener block to be notified when the value changes
	///
	/// The 'object' is used to determine the lifetime of the listener. If not specified, the register ties the lifetime
	/// of the listener to the lifetime of this object. The 'object' is held weakly to avoid retain cycles.
	///
	/// - Parameters:
	///   - object: The registering object.
	///   - changeBlock: The block to call when the value in the ValueBinder instance changes
	func register(_ object: AnyObject? = nil, _ changeBlock: @escaping (ValueType) -> Void) {
		if #available(macOS 10.12, *) {
			os_log("%@ [%@] register", log: .default, type: .debug, self.selfTypeString, self.identifier)
		}
		else {
			// Fallback on earlier versions
		}

		// First a little housekeeping...
		self.cleanupInactiveBindings()

		// Add the binding. If a lifetime object isn't specified, ties the lifetime of the binding to the binding itself
		self.bindings.append(Binding(object ?? self, changeBlock))

		// Call with the initial value to initialize the binding object's state
		changeBlock(self.wrappedValue)
	}

	/// Deregister a listener binding
	/// - Parameters:
	///   - object: The object to deregister
	func deregister(_ object: AnyObject) {
		if #available(macOS 10.12, *) {
			os_log("%@ [%@] deregister", log: .default, type: .debug, self.selfTypeString, self.identifier)
		}
		else {
			// Fallback on earlier versions
		}
		self.bindings = self.bindings.filter { $0.isAlive && $0.object !== object }
	}

	/// Deregister all listeners
	func deregisterAll() {
		self.bindings.forEach { $0.deregister() }
		self.bindings = []
	}
}

// Conveniences for combine

@available(macOS 10.15, iOS 13, tvOS 13, *)
public extension ValueBinder {
	/// Attaches a subscriber with closure-based behavior to a publisher that never fails.
	/// Returns `nil` if the publisher isn't available
	func sink(receiveValue: @escaping ((ValueType) -> Void)) -> AnyCancellable? {
		self.publisher?.passthroughSubject.sink(receiveValue: receiveValue)
	}

	/// Attaches a subscriber with closure-based behavior. Returns `nil` if the publisher isn't available
	func sink(
		 receiveCompletion: @escaping ((Subscribers.Completion<Never>) -> Void),
		 receiveValue: @escaping ((ValueType) -> Void)
	) -> AnyCancellable? {
		self.publisher?.passthroughSubject.sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
	}
}

// MARK: - Value handling

private extension ValueBinder {
	// Remove any inactive bindings
	func cleanupInactiveBindings() {
		self.bindings = self.bindings.filter { $0.isAlive }
	}
}
