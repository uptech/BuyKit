import Foundation

class WeakWrapper<T> {
    public var value: T?

    public init(_ value: T?) {
        self.value = value
    }
}
