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
		let disposeBag = MemoryDisposeBag()
		autoreleasepool {
			let boolBinding = ValueBinder(true) { newValue in
				Swift.print("value now \(newValue)")
			}
			disposeBag.add(boolBinding)

			let orig = Wrapper("orig", wrapper: boolBinding)
			let togg = Wrapper("togg", wrapper: boolBinding.toggled())

			XCTAssertEqual(true, orig.binder.wrappedValue)
			XCTAssertEqual(false, togg.binder.wrappedValue)

			boolBinding.wrappedValue = false

			XCTAssertEqual(false, orig.binder.wrappedValue)
			XCTAssertEqual(true, togg.binder.wrappedValue)

			XCTAssertFalse(disposeBag.isEmpty())
		}

		// Check that the deinit was successfully called
		XCTAssertTrue(disposeBag.isEmpty())
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

		// For detecting that the ValueBinders are cleaning themselves up correctly
		let bag = MemoryDisposeBag()

		autoreleasepool {
			let intBinding = ValueBinder<Int>(10)
			bag.add(intBinding)
			let wordsBinding = intBinding.asWords(locale: Locale(identifier: "en_US"))
			bag.add(wordsBinding)
			let frenchBinding = intBinding.asWords(locale: Locale(identifier: "fr_FR"))
			bag.add(frenchBinding)

			XCTAssertEqual("ten", wordsBinding.wrappedValue)
			XCTAssertEqual("dix", frenchBinding.wrappedValue)

			intBinding.wrappedValue = 945
			XCTAssertEqual("nine hundred forty-five", wordsBinding.wrappedValue)
			XCTAssertEqual("neuf cent quarante-cinq", frenchBinding.wrappedValue)

			XCTAssertFalse(bag.isEmpty())
		}

		XCTAssertTrue(bag.isEmpty())
	}

	func testIntToStringTransformer() throws {
		let intBinding = ValueBinder<Int>(10)
		let intStringBinding = intBinding.stringValue()
		let doubleBinding = ValueBinder<Double>(99.343)
		let doubleStringBinding = doubleBinding.stringValue()

		XCTAssertEqual("10", intStringBinding.wrappedValue)
		XCTAssertEqual("99.343", doubleStringBinding.wrappedValue)

		intBinding.wrappedValue = 22910
		XCTAssertEqual("22910", intStringBinding.wrappedValue)

		doubleBinding.wrappedValue = -15.6
		XCTAssertEqual("-15.6", doubleStringBinding.wrappedValue)
	}

	func testDoubleToIntTransform() throws {
		let doubleBinding = ValueBinder<Double>(99.343)
		let intBinding = doubleBinding.intValue()

		XCTAssertEqual(99, intBinding.wrappedValue)

		doubleBinding.wrappedValue = -5.3332
		XCTAssertEqual(-5, intBinding.wrappedValue)

		// Dumb check that we're not feeding back up
		intBinding.wrappedValue = 1101
		XCTAssertEqual(-5.3332, doubleBinding.wrappedValue)

		doubleBinding.wrappedValue = 99984.22214
		XCTAssertEqual(99984, intBinding.wrappedValue)
	}

	func testIntToWords() throws {
		let oneBinding = ValueBinder<Int>(1)
		let wordsBinding = oneBinding.asWords(locale: Locale(identifier: "en_AU"))
		let zhBinding = oneBinding.asWords(locale: Locale(identifier: "zh"))

		XCTAssertEqual(wordsBinding.wrappedValue, "one")
		XCTAssertEqual(zhBinding.wrappedValue, "一")

		oneBinding.wrappedValue = 2
		XCTAssertEqual(wordsBinding.wrappedValue, "two")
		XCTAssertEqual(zhBinding.wrappedValue, "二")

		oneBinding.wrappedValue = 135
		XCTAssertEqual(wordsBinding.wrappedValue, "one hundred thirty-five")
		XCTAssertEqual(zhBinding.wrappedValue, "一百三十五")
	}

	func testURLtoFilePath() throws {
		let urlBinding = ValueBinder<URL>(URL(string: "file:///tmp/my-folder/output.pdf")!)
		let filePath = urlBinding.filePath()

		XCTAssertEqual(filePath.wrappedValue, "/tmp/my-folder/output.pdf")

		urlBinding.wrappedValue = URL(string: "file:///Users/noodle/Documents/myDoc.txt")!
		XCTAssertEqual(filePath.wrappedValue, "/Users/noodle/Documents/myDoc.txt")
	}

	func testNumberFormatter() throws {
		let doubleValue = ValueBinder(25.66789)

		let nf1 = NumberFormatter { $0.maximumFractionDigits = 2 }
		let nfv1 = doubleValue.stringValue(using: nf1, nilValue: "oops")
		XCTAssertEqual("25.67", nfv1.wrappedValue)

		let nf2 = NumberFormatter { $0.maximumFractionDigits = 0 }
		let nfv2 = doubleValue.stringValue(using: nf2, nilValue: "oops")
		XCTAssertEqual("26", nfv2.wrappedValue)
	}

	func testDefaultNumber() throws {
		do {
			let doubleValue = ValueBinder<Double?>(25.66789)
			let dv2 = doubleValue.unwrappingValue(usingDefault: -13)
			XCTAssertEqual(25.66789, doubleValue.wrappedValue)
			XCTAssertEqual(25.66789, dv2.wrappedValue)

			doubleValue.wrappedValue = nil
			XCTAssertEqual(-13, dv2.wrappedValue)
		}

		do {
			let intValue = ValueBinder<Int?>(3)
			let dv2 = intValue.unwrappingValue(usingDefault: -1)

			intValue.wrappedValue = 2
			XCTAssertEqual(2, intValue.wrappedValue)
			XCTAssertEqual(2, dv2.wrappedValue)

			intValue.wrappedValue = nil
			XCTAssertEqual(-1, dv2.wrappedValue)
		}
	}



	func testCleanupTransforms() throws {

		let detector = MemoryDisposeBag()

		autoreleasepool {
			let intValue = ValueBinder<Int?>(3)
			detector.add(intValue)
			let dv2 = intValue.unwrappingValue(usingDefault: -1)
			detector.add(dv2)

			intValue.wrappedValue = 2
			XCTAssertEqual(2, intValue.wrappedValue)
			XCTAssertEqual(2, dv2.wrappedValue)

			intValue.wrappedValue = nil
			XCTAssertEqual(-1, dv2.wrappedValue)

			XCTAssertFalse(detector.isEmpty())
		}

		// Make sure the binders have been cleaned up
		XCTAssertTrue(detector.isEmpty())
	}
}
