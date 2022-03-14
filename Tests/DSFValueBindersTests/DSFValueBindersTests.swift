@testable import DSFValueBinders
import XCTest

final class DSFValueBindersTests: XCTestCase {
	class Counter {
		var count = 0
	}

	func testForcedBinding() throws {
		class ValueChecker {
			let intBinder: ValueBinder<Int>
			init(_ value: ValueBinder<Int>, counter: Counter) {
				self.intBinder = value
				self.intBinder.register(self) { newValue in
					counter.count += 1
					Swift.print("value changed \(newValue)")
				}
			}

			deinit {
				// Forcing a removal before deletion
				Swift.print("ValueChecker: deinit")
				intBinder.deregister(self)
			}
		}

		let counter = Counter()
		let intValue = ValueBinder<Int>(0, "Value")

		autoreleasepool {
			let boundObject = ValueChecker(intValue, counter: counter)
			// There will already be ONE value, as the binder calls the 'change' function on
			// creation to make sure that the initial values are set correctly
			XCTAssertEqual(1, counter.count)

			intValue.wrappedValue = 4
			XCTAssertEqual(2, counter.count)

			intValue.wrappedValue = 1000
			XCTAssertEqual(3, counter.count)

			_ = boundObject // To remove warning
		}

		// At this point, the ValueChecker object should be gone (the binder has a weak reference to it,
		// so it should NOT be held by the binding object.)
		intValue.wrappedValue = -3
		XCTAssertEqual(3, counter.count)
	}

	func testUnforcedBinding() throws {
		class ValueChecker: NSObject {
			init(_ intBinder: ValueBinder<Int>, counter: Counter) {
				super.init()
				intBinder.register(self) { newValue in
					counter.count += 1
					Swift.print("value changed \(newValue)")
				}
			}

			deinit {
				Swift.print("ValueChecker: deinit")
				// Binding will be auto-removed from the binder due to weak binding
			}
		}

		let counter = Counter()
		let intValue = ValueBinder<Int>(0, "Value")

		autoreleasepool {
			let boundObject = ValueChecker(intValue, counter: counter)
			// There will already be ONE value, as the binder calls the 'change' function on
			// creation to make sure that the initial values are set correctly
			XCTAssertEqual(1, counter.count)

			intValue.wrappedValue = 4
			XCTAssertEqual(2, counter.count)

			intValue.wrappedValue = 1000
			XCTAssertEqual(3, counter.count)

			_ = boundObject // To remove warning
		}

		// At this point, 'boundObject' should be gone (the binder has a weak reference to it,
		// so it should NOT be held by the binding object.)
		// Updating the binding value here should NOT result in a change
		intValue.wrappedValue = -3
		XCTAssertEqual(3, counter.count)
	}

	func testSimpleKeypath() {
		@objc class ContainerObject: NSObject {
			// The dynamic property to bind to
			@objc dynamic var intValue = 333
			// Our binding object
			lazy var kp = try! KeyPathBinder(self, keyPath: \.intValue) { newValue in
				Swift.print("*** KeyPathBinder completion handler called - value is \(String(describing: newValue))")
			}

			// Something learned. Don't try setting the keypath _value_ in the initializer here,
			// as the observation doesn't seem to be valid until the initializer is complete.
		}

		autoreleasepool {
			let kpo = ContainerObject()

			// Initial value (333) should have been set as soon as the KeyPathBinding object is created
			XCTAssertEqual(333, kpo.kp.wrappedValue)
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)

			// Set the value of the keypath. The value should flow through to the KeyPathBinder object
			kpo.intValue = 224
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)

			// Set the value of the KeyPathBinding directly. It should flow back to the actual keypath
			kpo.kp.wrappedValue = 100
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)

			// Set the value of the keypath. The value should flow through to the KeyPathBinder object
			kpo.intValue = -99999
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)

			// Set the value of the keypath. The value should flow through to the KeyPathBinder object
			kpo.intValue = 12_345_678
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)

			// Set the value of the KeyPathBinding directly. It should flow back to the actual keypath
			kpo.kp.wrappedValue = -1
			XCTAssertEqual(kpo.intValue, kpo.kp.wrappedValue)
		}
	}

	func testValuePublishingValues() {
		let vb = ValueBinder("Noodles")

		let expectation = XCTestExpectation()
		var results: [String] = []

		let cancellable = vb.passthroughSubject.sink { newValue in
			results.append(newValue)
			if results.count == 3 {
				expectation.fulfill()
			}
		}

		vb.wrappedValue = "caterpillar"
		vb.wrappedValue = "fish"
		vb.wrappedValue = "lots of trees"

		self.wait(for: [expectation], timeout: 5.0)

		XCTAssertEqual(["caterpillar", "fish", "lots of trees"], results)

		cancellable.cancel()

		do {
			let expectation = XCTestExpectation()
			let cancellable = vb.passthroughSubject.sink { newValue in
				results.append(newValue)
				expectation.fulfill()
			}

			vb.wrappedValue = "yum cha"
			self.wait(for: [expectation], timeout: 5.0)
			XCTAssertEqual(["caterpillar", "fish", "lots of trees", "yum cha"], results)
			cancellable.cancel()
		}
	}

	func testKeyPathPublishingValues() {
		@objc class ContainerObject: NSObject {
			// The dynamic property to bind to
			@objc dynamic var doubleValue = 1.234
			// Our binding object
			lazy var kp: KeyPathBinder<ContainerObject, Double> = try! .init(self, keyPath: \.doubleValue) { newValue in
				Swift.print("*** KeyPathBinder completion handler called - value is \(String(describing: newValue))")
			}

			// Something learned. Don't try setting the keypath _value_ in the initializer here,
			// as the observation doesn't seem to be valid until the initializer is complete.
		}

		let expectation = XCTestExpectation()
		var results: [Double?] = []

		let co = ContainerObject()

		let cancellable = co.kp.passthroughSubject.sink { newValue in
			results.append(newValue)
			if results.count == 3 {
				expectation.fulfill()
			}
		}

		// Set via the keypath
		co.doubleValue = 1.2345
		XCTAssertEqual(results[0], 1.2345)

		// Set via the keypath
		co.doubleValue = -15.6
		XCTAssertEqual(results[1], -15.6)

		// Set via the wrapped value (which should reflect back through to the double value)
		co.kp.wrappedValue = 1123
		XCTAssertEqual(results[2], 1123)
		XCTAssertEqual(1123, co.doubleValue)

		self.wait(for: [expectation], timeout: 5.0)
		XCTAssertEqual([1.2345, -15.6, 1123], results)

		cancellable.cancel()
	}

	func testDoco1() {
		class MyObject: NSObject {
			// A dynamic value. Could be bound to a UI control via IB (for example)
			@objc dynamic var dynamicValue: Double = 0
			// The binder object
			lazy var binder = try! KeyPathBinder(self, keyPath: \.dynamicValue) { newValue in
				Swift.print("> new value is \(String(describing: newValue))")
			}

			func doUpdate() {
				// Update the dynamicValue via the binder
				binder.wrappedValue = -9876.54
				// Update the binder via the dynamicValue
				dynamicValue = 1024.56
			}
		}

		let o = MyObject()
		o.doUpdate()
	}

	func testDoco2() {
		class controller {
			let countBinder = ValueBinder<Int>(999) { newValue in
				Swift.print("Controller object notifies change: \(newValue)")
			}
			lazy var one = One(countBinder)
			lazy var two = Two(countBinder)
		}

		class One {
			private let _countBinder: ValueBinder<Int>
			init(_ countBinder: ValueBinder<Int>) {
				_countBinder = countBinder
				// Listen for changes to the binder
				_countBinder.register(self) { newValue in
					// Do something with 'newValue'
					Swift.print("One object notifies change: \(newValue)")
				}
			}
			func update() {
				_countBinder.wrappedValue = 11
			}
		}

		class Two {
			private let _countBinder: ValueBinder<Int>
			init(_ countBinder: ValueBinder<Int>) {
				_countBinder = countBinder
				// Listen for changes to the binder
				_countBinder.register(self) { newValue in
					// Do something with 'newValue'
					Swift.print("Two object notifies change: \(newValue)")
				}
			}
			func update() {
				_countBinder.wrappedValue = 22
			}
		}

		let c = controller()
		c.one.update()
		c.two.update()
	}
}

#if os(macOS)
final class DSFValueBindersMacOnlyTests: XCTestCase {

	func testKeyPathState() throws {

		class MyViewController: NSViewController {
			@objc dynamic var buttonState = NSControl.StateValue.on

			lazy var boundKeyPath: KeyPathBinder<MyViewController, NSControl.StateValue> = {
				return try! .init(self, keyPath: \.buttonState) { newValue in
					Swift.print("boundKeyPath notifies change: \(newValue)")
				}
			}()

			init() {
				super.init(nibName: nil, bundle: nil)
				_ = boundKeyPath
			}

			required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}

			func resetState() {
				boundKeyPath.wrappedValue = .on
			}

		}

		let obj = MyViewController()

		obj.buttonState = .off
		XCTAssertEqual(.off, obj.boundKeyPath.wrappedValue)
		obj.buttonState = .mixed
		XCTAssertEqual(.mixed, obj.boundKeyPath.wrappedValue)

		obj.resetState()
		XCTAssertEqual(.on, obj.buttonState)
	}
}
#endif
