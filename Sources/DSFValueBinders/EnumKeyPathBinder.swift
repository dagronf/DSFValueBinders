//
//  EnumKeyPathBinder.swift
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

/// A specialized KeyPath binder specifically for enum types.
///
/// Simple example :-
///
/// ```swift
/// class ViewController: NSViewController {
///    // A dynamic value. Could be bound to a UI control via IB (for example)
///    @objc dynamic var toolbarSize: NSToolbar.SizeMode = .regular
///    // The binder object
///    lazy var binder = try! EnumKeyPathBinder(self, keyPath: \.toolbarSize) { newValue in
///       Swift.print("> new value is \(newValue)")
///    }
///    ...
///    // Update the dynamicValue via the binder
///    self.binder.wrappedValue = .small
///    // Update the binder via its dynamic variable
///    self.toolbarSize = .regular
/// }
/// ```
///
/// generates the output:
/// ```
/// > new value is NSToolbarSizeMode(rawValue: 2)
/// > new value is NSToolbarSizeMode(rawValue: 1)
/// ```
public class EnumKeyPathBinder<ClassType: NSObject, ValueType: RawRepresentable>: ValueBinder<ValueType> {
	/// Create a key path binding object for an enum value
	/// - Parameters:
	///   - object: The object containing the key path to observe
	///   - keyPath: The key path to observe
	///   - identifier: Binder identifier
	///   - callback: An optional block that is called when the value of the binder changes
	///   Throws `ValueBinderErrors.invalidKeyPath` if the object.keyPath is invalid
	public init(
		_ object: ClassType,
		keyPath: KeyPath<ClassType, ValueType>,
		_ identifier: String = "",
		_ callback: ((ValueType) -> Void)? = nil
	) throws {
		self.callback = callback
		self.object = object

		// A bit hacky - we need the STRING representation of the keypath for NSObject's calls later.
		let stringKeyPath = NSExpression(forKeyPath: keyPath).keyPath
		guard !stringKeyPath.isEmpty else {
			throw ValueBinderErrors.invalidKeyPath
		}
		self.stringPath = stringKeyPath

		// Grab out the initial value from the bound keypath.
		// If we cannot get a valid value from the keypath then throw an error (maybe it's a type mismatch?)
		guard
			let raw = object.value(forKeyPath: stringKeyPath) as? ValueType.RawValue,
			let initialValue = ValueType(rawValue: raw)
		else {
			Swift.print("The specified key path couldn't be resolved")
			throw ValueBinderErrors.keyPathInvalidValue
		}

		super.init(initialValue, identifier)

		// Start listening for kvo changes
		self.kvoObservation = object.observe(keyPath, options: [.new]) { [weak self] obj, value in
			if let raw = obj.value(forKeyPath: stringKeyPath) as? ValueType.RawValue,
			   let newValue = ValueType(rawValue: raw)
			{
				self?.kvoUpdate(newValue)
			}
		}
	}

	deinit {
		self.kvoObservation = nil
	}

	private weak var object: ClassType?
	private var kvoObservation: NSKeyValueObservation?
	private let stringPath: String
	private let lock = NSLock()
	private let callback: ((ValueType) -> Void)?

	// MARK: - Change handling

	private func kvoUpdate(_ value: ValueType) {
		self.lock.tryLock {
			// The bound keypath has changed (and it's not from us). Update the value
			self.wrappedValue = value

			os_log(
				"%@ [%@] value update to '%@'",
				log: .default,
				type: .debug,
				"\(type(of: self))",
				"\(self.identifier)",
				"\(self.wrappedValue)"
			)

			self.callback?(value)
		}
	}

	override public func valueDidChange() {
		super.valueDidChange()

		self.lock.tryLock {
			os_log(
				"%@ [%@] value update to '%@'",
				log: .default,
				type: .debug,
				"\(type(of: self))",
				"\(self.identifier)",
				"\(self.wrappedValue)"
			)

			// Push the new value through to the bound keypath
			object?.setValue(self.wrappedValue.rawValue, forKey: stringPath)
			self.callback?(self.wrappedValue)
		}
	}
}
