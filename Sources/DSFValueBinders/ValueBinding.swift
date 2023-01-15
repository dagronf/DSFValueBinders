@propertyWrapper
public struct ValueBinding<T> {
    
    private let valueBinder: ValueBinder<T>
    
    public var wrappedValue: T {
        set { valueBinder.wrappedValue = newValue }
        get { valueBinder.wrappedValue }
    }
    
    public init(wrappedValue: T) {
        self.valueBinder = .init(wrappedValue)
    }
    
    public var projectedValue: ValueBinder<T> {
        valueBinder
    }
}
