# DSFValueBinders

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/DSFValueBinders" />
    <img src="https://img.shields.io/badge/macOS-10.12+-red" />
    <img src="https://img.shields.io/badge/iOS-13+-blue" />
    <img src="https://img.shields.io/badge/tvOS-13+-orange" />
    <img src="https://img.shields.io/badge/mac Catalyst-supported-green" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.3-orange.svg" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

## ValueBinder

A ValueBinder creates a two-way binding object to allow sharing of a value between objects.

This is mildly similar to `@Binding` in SwiftUI but doesn't rely on SwiftUI - meaning it can be used pretty much anywhere Swift can.

### Creating

You can define a binder using the standard initializer.

This initializer also allows you to supply a callback block that gets triggered when the `wrappedValue` changes.

```swift
let countBinder = ValueBinder<Int>(0) { newValue in
   Swift.print("countBinder changed: \(newValue)")
}
...
countBinder.wrappedValue = 4  // triggers the update callback
```

### Registering for change updates

You can hand your ValueBinding object to another class which can supply a block to be called when the `ValueBinder` wrapped value changes.

```swift
class AnotherClass {
   init(_ binder: ValueBinder<Int>) {
      binder.register(self) { newValue in
         Swift.print("Binding detected change: \(newValue)")
      }
   }
}
```

Additionally, if you hold on to the binder object your class can update the ValueBinder value too!

```swift
class AnotherClass {
   let countBinder: ValueBinder<Int> 
   init(_ binder: ValueBinder<Int>) {
      countBinder = binder
      countBinder.register(self) { newValue in
         Swift.print("Binding detected change: \(newValue)")
      }
   }
   
   func userPressed() {
      countBinder.wrappedValue += 1
   }
}
```

### Updating the ValueBinder value

Any object that holds a `ValueBinder` object can update the wrapped value. 

```swift
_countBinder.wrappedValue += 1
```

All objects that have registered for change callbacks will be notified of the change in value.

## KeyPathBinder

A `KeyPathBinder` is a specialization of the `ValueBinder` that can track a dynamic keypath

```swift
// The dynamic property to bind to. This might be (for example) bound to a control from interface builder.
@objc dynamic var state: NSControl.State = .on

// Our binding object
lazy var boundKeyPath: KeyPathBinder<MyViewController, NSControl.StateValue> = {
   return try! .init(self, keyPath: \.buttonState) { newValue in
      Swift.print("boundKeyPath notifies change: \(String(describing: newValue))")
   }
}()
```

## EnumKeyPathBinder

An `EnumKeyPathBinder` is a keypath binder for observing Swift `enum` types.

I had a situation where I was tring to use a `KeyPathBinder` on the size mode for a toolbar which is of type 
`NSToolbar.SizeMode`, and it continually failed. However, binding to `NSControl.StateValue` on a control worked fine.

The result was that `NSControl.StateValue`, while appearing _like_ an enum is actually a struct, whereas `NSToolbar.SizeMode`
is an enum (specifically, a RawRepresentable).  The issue appears when trying to observe enum type changes, so this class
is a specialization of `KeyPathBinder` specifically for observing such enum types.

## Combine

Both binder types expose a property `publisher` which you can hook up to your combine workflow.

If the OS doesn't support Combine, the `publisher` property will be nil.

```swift
let binder = ValueBinder(0) 
...
let cancellable = binder.publisher?.sink { newValue in
   // do something with `newValue`
}
```

## License

```
MIT License

Copyright (c) 2022 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
