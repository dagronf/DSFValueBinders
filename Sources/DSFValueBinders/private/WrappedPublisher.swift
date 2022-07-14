//
//  WrappedPublisher.swift
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

#if canImport(Combine)
import Combine
#endif

/// A combine publisher wrapper to abstract away the complexities of including publishing support
/// without breaking older os builds
public class WrappedPublisher<ValueType> {
	/// Create a wrapped publisher
	public init?() {
		guard #available(OSX 10.15, iOS 13, tvOS 13, *) else {
			return nil
		}
		self._publisher = PassthroughSubject<ValueType, Never>()
	}

	// Our type-erased publisher so that we can handle pre-Combine versions of the OS
	private let _publisher: AnyObject
}

// Combine publisher

@available(macOS 10.15, iOS 13, tvOS 13, *)
public extension WrappedPublisher {
	/// Combine publisher.
	///
	/// Note that the publisher will send events on non-main threads, so its important
	/// for your listeners to swap to the main thread if they are updating UI
	var publisher: AnyPublisher<ValueType, Never> {
		return self.passthroughSubject.eraseToAnyPublisher()
	}
}

// Publisher conveniences

@available(macOS 10.15, iOS 13, tvOS 13, *)
public extension WrappedPublisher {
	/// Sends a value to the subscriber.
	func send(_ input: ValueType) {
		self.passthroughSubject.send(input)
	}

	/// Attaches a subscriber with closure-based behavior to a publisher that never fails.
	func sink(receiveValue: @escaping ((ValueType) -> Void)) -> AnyCancellable {
		self.passthroughSubject.sink(receiveValue: receiveValue)
	}

	/// Attaches a subscriber with closure-based behavior.
	func sink(
		receiveCompletion: @escaping ((Subscribers.Completion<Never>) -> Void),
		receiveValue: @escaping ((ValueType) -> Void)
	) -> AnyCancellable {
		self.passthroughSubject.sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
	}
}

// Private

// swiftlint:disable force_cast

@available(macOS 10.15, iOS 13, tvOS 13, *)
internal extension WrappedPublisher {
	// Internal publisher to allow us to send new values
	var passthroughSubject: PassthroughSubject<ValueType, Never> {
		return self._publisher as! PassthroughSubject<ValueType, Never>
	}
}
