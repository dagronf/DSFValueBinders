@testable import DSFValueBinders
import XCTest

// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable identifier_name
// swiftlint:disable force_try
// swiftlint:disable type_body_length

final class ValueBindersExtensionTests: XCTestCase {

	class Wrapper: NSObject {
		let binder: ValueBinder<Bool>
		init(_ title: String, wrapper: ValueBinder<Bool>) {
			self.binder = wrapper
			super.init()
			wrapper.register(self) { newValue in
				Swift.print("\(title): newValue = \(newValue)")
			}
		}
	}

	func testToggled() throws {
		weak var bVal: ValueBinder<Bool>?
		autoreleasepool {
			let boolBinding = ValueBinder(true) { newValue in
				Swift.print("value now \(newValue)")
			}
			bVal = boolBinding

			let orig = Wrapper("orig", wrapper: boolBinding)
			let togg = Wrapper("togg", wrapper: boolBinding.toggled())

			XCTAssertEqual(true, orig.binder.wrappedValue)
			XCTAssertEqual(false, togg.binder.wrappedValue)

			boolBinding.wrappedValue = false

			XCTAssertEqual(false, orig.binder.wrappedValue)
			XCTAssertEqual(true, togg.binder.wrappedValue)
		}

		// Check that the deinit was successfully called
		XCTAssertNil(bVal)
	}

	func testValueBinderTransform1() throws {

		class Wrapper: NSObject {
			let binder: ValueBinder<Int>
			init(_ title: String, wrapper: ValueBinder<Int>) {
				self.binder = wrapper
				super.init()
				wrapper.register(self) { newValue in
					Swift.print("\(title): newValue = \(newValue)")
				}
			}
		}

		weak var bVal: ValueBinder<Int>?
		autoreleasepool {
			let intBinding = ValueBinder(0) { newValue in
				Swift.print("value now \(newValue)")
			}
			bVal = intBinding

			let orig = Wrapper("orig", wrapper: intBinding)
			let togg = Wrapper("togg", wrapper: intBinding.transform { newValue in
				10 - newValue
			})

			XCTAssertEqual(0, orig.binder.wrappedValue)
			XCTAssertEqual(10, togg.binder.wrappedValue)

			intBinding.wrappedValue = 10
			XCTAssertEqual(10, orig.binder.wrappedValue)
			XCTAssertEqual(0, togg.binder.wrappedValue)

			intBinding.wrappedValue = 3

			XCTAssertEqual(3, orig.binder.wrappedValue)
			XCTAssertEqual(7, togg.binder.wrappedValue)
		}

		// Check that the deinit was successfully called
		XCTAssertNil(bVal)

		weak var intB: ValueBinder<Int>?
		weak var traB: ValueBinder<Int>?
		autoreleasepool {
			let intBinding = ValueBinder(0)
			let mappedBinding = intBinding.transform { newValue in
				10 - newValue
			}
			intB = intBinding
			traB = mappedBinding

			let orig = Wrapper("orig", wrapper: intBinding)
			let togg = Wrapper("togg", wrapper: mappedBinding)

			XCTAssertEqual(0, orig.binder.wrappedValue)
			XCTAssertEqual(10, togg.binder.wrappedValue)

			intBinding.wrappedValue = 10
			XCTAssertEqual(10, orig.binder.wrappedValue)
			XCTAssertEqual(0, togg.binder.wrappedValue)

			intBinding.wrappedValue = 3

			XCTAssertEqual(3, orig.binder.wrappedValue)
			XCTAssertEqual(7, togg.binder.wrappedValue)
		}

		// Check that the when the binding goes out of scope all the associated bindings disappear
		XCTAssertNil(intB)
		XCTAssertNil(traB)
	}

	func testIntWords() throws {

		weak var ib1: ValueBinder<Int>?
		weak var wb1: ValueBinder<String>?
		weak var fb1: ValueBinder<String>?

		autoreleasepool {
			let intBinding = ValueBinder<Int>(10)
			ib1 = intBinding
			let wordsBinding = intBinding.asWords(locale: Locale(identifier: "en_US"))
			wb1 = wordsBinding
			let frenchBinding = intBinding.asWords(locale: Locale(identifier: "fr_FR"))
			fb1 = frenchBinding

			XCTAssertEqual("ten", wordsBinding.wrappedValue)
			XCTAssertEqual("dix", frenchBinding.wrappedValue)

			intBinding.wrappedValue = 945
			XCTAssertEqual("nine hundred forty-five", wordsBinding.wrappedValue)
			XCTAssertEqual("neuf cent quarante-cinq", frenchBinding.wrappedValue)
		}

		XCTAssertNil(fb1)
		XCTAssertNil(wb1)
		XCTAssertNil(ib1)
	}
}
