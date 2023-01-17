@testable import DSFValueBinders
import XCTest

import Foundation

// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable identifier_name
// swiftlint:disable force_try
// swiftlint:disable type_body_length

private class ValueChecker<RAWTYPE>: NSObject {
	init(_ binder: ValueBinder<RAWTYPE>) {
		super.init()
		binder.register(self) { [weak self] newValue in
			Swift.print("value changed \(newValue)")
			self?.bindingValue = newValue
		}
	}

	private(set) var bindingValue: RAWTYPE?

	deinit {
		Swift.print("ValueChecker: deinit")
	}
}

final class PropertyWrapperTests: XCTestCase {
	func testPropertyWrapperWorks() throws {
		// Keep a weak handle to the created valuebinder to check whether
		// it is being deinit-ed correctly
		weak var intHolder: ValueBinder<Int>?

		autoreleasepool {
			@ValueBinding var count: Int = -222

			// weakly store the handle for later checks
			intHolder = $count
			XCTAssertNotNil(intHolder)

			var registerValue: Int = -1

			// Register a block for updates
			$count.register { newValue in
				registerValue = newValue
			}

			let vc = ValueChecker<Int>($count)

			// The binding value within the checking class should automatically reflect
			XCTAssertEqual(-222, vc.bindingValue)
			XCTAssertEqual(-222, registerValue)

			// Change the count value
			count = 100
			XCTAssertEqual(100, vc.bindingValue)
			XCTAssertEqual(100, registerValue)
		}

		// Make sure that the valuebinder has been released
		XCTAssertNil(intHolder)
	}
}
