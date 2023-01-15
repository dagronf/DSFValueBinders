@testable import DSFValueBinders
import XCTest

// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable identifier_name
// swiftlint:disable force_try
// swiftlint:disable type_body_length

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
		var results: [String] = []
		
		do {
			let expectation = XCTestExpectation()
			
			let cancellable = vb.publisher?.sink { newValue in
				results.append(newValue)
				if results.count == 3 {
					expectation.fulfill()
				}
			}
			XCTAssertNotNil(cancellable)
			
			vb.wrappedValue = "caterpillar"
			vb.wrappedValue = "fish"
			vb.wrappedValue = "lots of trees"
			
			self.wait(for: [expectation], timeout: 5.0)
			
			XCTAssertEqual(["caterpillar", "fish", "lots of trees"], results)
			
			cancellable!.cancel()
		}
		
		do {
			let expectation = XCTestExpectation()
			let cancellable = vb.sink { newValue in
				results.append(newValue)
				expectation.fulfill()
			}
			XCTAssertNotNil(cancellable)
			
			vb.wrappedValue = "yum cha"
			self.wait(for: [expectation], timeout: 5.0)
			XCTAssertEqual(["caterpillar", "fish", "lots of trees", "yum cha"], results)
			cancellable!.cancel()
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
		
		let cancellable = co.kp.sink { newValue in
			results.append(newValue)
			if results.count == 3 {
				expectation.fulfill()
			}
		}
		XCTAssertNotNil(cancellable)
		
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
		
		cancellable?.cancel()
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
				do {
					// Update the dynamicValue via the binder
					self.binder.wrappedValue = -9876.54
					
					// Check that the dynamic var has the correct value
					XCTAssertEqual(-9876.54, self.dynamicValue)
				}
				
				do {
					// Update the binder via the dynamicValue
					self.dynamicValue = 1024.56
					
					// Check the binder has the updated value
					XCTAssertEqual(1024.56, self.binder.wrappedValue)
				}
			}
		}
		
		let o = MyObject()
		o.doUpdate()
	}
	
	func testDoco2() {
		class TestController {
			let countBinder = ValueBinder<Int>(999) { newValue in
				Swift.print("Controller object notifies change: \(newValue)")
			}
			
			lazy var one = One(countBinder)
			lazy var two = Two(countBinder)
		}
		
		class One {
			private let _countBinder: ValueBinder<Int>
			init(_ countBinder: ValueBinder<Int>) {
				self._countBinder = countBinder
				// Listen for changes to the binder
				self._countBinder.register(self) { newValue in
					// Do something with 'newValue'
					Swift.print("One object notifies change: \(newValue)")
				}
			}
			
			func update() {
				self._countBinder.wrappedValue = 11
			}
		}
		
		class Two {
			private let _countBinder: ValueBinder<Int>
			init(_ countBinder: ValueBinder<Int>) {
				self._countBinder = countBinder
				// Listen for changes to the binder
				self._countBinder.register(self) { newValue in
					// Do something with 'newValue'
					Swift.print("Two object notifies change: \(newValue)")
				}
			}
			
			func update() {
				self._countBinder.wrappedValue = 22
			}
		}
		
		let c = TestController()
		c.one.update()
		c.two.update()
	}
	
	@objc enum TestingType: Int {
		case initial = 0
		case first = 1
		case second = 2
	}
	
	func testEnumKeyPathBinding() {
		@objc class Container: NSObject {
			let deleteExp: XCTestExpectation
			
			@objc public dynamic var testingMode = TestingType.initial
			lazy var currentValue: TestingType = self.testingMode
			
			lazy var boundKeyPath: EnumKeyPathBinder<Container, TestingType> = try! .init(self, keyPath: \.testingMode) { [weak self] newValue in
				Swift.print("boundKeyPath notifies change: \(newValue)")
				self?.currentValue = newValue
			}
			
			init(_ deleteExp: XCTestExpectation) {
				self.deleteExp = deleteExp
				super.init()
				_ = self.boundKeyPath
			}
			
			deinit {
				Swift.print("Container: deinit")
				deleteExp.fulfill()
			}
		}
		
		let deletionCheck = XCTestExpectation()
		
		autoreleasepool {
			// Check for callbacks on registered listeners
			// There should be 4 updates on the registered callback
			let exp = XCTestExpectation()
			exp.expectedFulfillmentCount = 4
			
			let c = Container(deletionCheck)
			XCTAssertEqual(.initial, c.testingMode)
			
			// Note that this will be called 4 times, as when the observer is registered we
			// trigger the callback with the current value for the binding
			c.boundKeyPath.register(self) { newValue in
				Swift.print("registered object received update: \(newValue)")
				exp.fulfill()
			}
			
			let expCombine = XCTestExpectation()
			expCombine.expectedFulfillmentCount = 3
			
			// Check for combine publishing on the enum observer
			let cancellable = c.boundKeyPath.sink { newValue in
				Swift.print("combine publisher received update: \(newValue)")
				expCombine.fulfill()
			}
			XCTAssertNotNil(cancellable)
			
			// To hide the 'unused' message in Xcode
			_ = cancellable
			
			// Check to see if the update block is called
			c.testingMode = .first
			XCTAssertEqual(.first, c.currentValue)
			
			// Check to see if the update block is called
			c.testingMode = .second
			XCTAssertEqual(.second, c.currentValue)
			
			// Update the keypath object directly
			c.boundKeyPath.wrappedValue = .initial
			XCTAssertEqual(.initial, c.currentValue)
			
			wait(for: [exp, expCombine], timeout: 2)
		}
		
		// Make sure that the container cleans up, which means that the
		// EnumKeyPathValue object has been deleted too
		wait(for: [deletionCheck], timeout: 5)
	}
	
	func testRegisterWeak() {
		class Wrapper: NSObject {
			init(wrapper: ValueBinder<Int>) {
				super.init()
				wrapper.register(self) { newValue in
					Swift.print("newValue = \(newValue)")
				}
			}
		}
		
		// A simple int binding
		let intBinding = ValueBinder(1) { newValue in
			Swift.print("intBinding value is now \(newValue)")
		}
		
		// The `intBinding` instance has a registered binding (the callback)
		XCTAssertEqual(1, intBinding.activeBindingCount)
		
		// Create a registered listener within an autorelease pool
		// so that we can force it to delete when needed
		autoreleasepool {
			let w = Wrapper(wrapper: intBinding)
			
			// We've added a binding
			XCTAssertEqual(2, intBinding.activeBindingCount)
			XCTAssertEqual(2, intBinding.totalBindingCount)
			intBinding.wrappedValue = 4
			
			// So that we don't lose the wrapper instance
			_ = w
		}
		
		// w has gone out of scope, should have been marked as inactive within the binding
		XCTAssertEqual(1, intBinding.activeBindingCount)
		
		// The total count will still be 2, as the binding array hasn't been cleared up yet
		XCTAssertEqual(2, intBinding.totalBindingCount)
		
		// If we change the value, the inactive bindings should be cleaned up and removed.
		intBinding.wrappedValue = 300
		XCTAssertEqual(1, intBinding.totalBindingCount)
		XCTAssertEqual(1, intBinding.activeBindingCount)
	}
}

// Tests for picking up the specific issue that I found in DSFToolbar

#if os(macOS)
final class DSFValueBindersMacOnlyTests: XCTestCase {
	func testKeyPathState() throws {
		class MyViewController: NSViewController {
			@objc dynamic var buttonState = NSControl.StateValue.on
			
			lazy var boundKeyPath: KeyPathBinder<MyViewController, NSControl.StateValue> = try! .init(self, keyPath: \.buttonState) { newValue in
				Swift.print("boundKeyPath notifies change: \(newValue)")
			}
			
			init() {
				super.init(nibName: nil, bundle: nil)
				_ = self.boundKeyPath
			}
			
			@available(*, unavailable)
			required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
			
			func resetState() {
				self.boundKeyPath.wrappedValue = .on
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
	
	@objc public dynamic var sizeMode = NSToolbar.SizeMode.regular
	func testEnum() {
		var exp = XCTestExpectation()
		
		let boundKeyPath: EnumKeyPathBinder<DSFValueBindersMacOnlyTests, NSToolbar.SizeMode> = try! .init(self, keyPath: \.sizeMode) { newValue in
			Swift.print("boundKeyPath notifies change: \(newValue)")
			exp.fulfill()
		}
		
		do {
			// Change the value via the dynamic value
			self.sizeMode = .small
			wait(for: [exp], timeout: 5)
			XCTAssertEqual(.small, boundKeyPath.wrappedValue)
		}
		
		do {
			exp = XCTestExpectation()
			// Change the value via the dynamic value
			self.sizeMode = .default
			wait(for: [exp], timeout: 5)
			XCTAssertEqual(.default, boundKeyPath.wrappedValue)
		}
	}
}

#endif
