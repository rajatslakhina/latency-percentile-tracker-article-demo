import Foundation

/// A fixed-capacity, O(1)-append ring buffer.
///
/// When the buffer is full, appending overwrites the oldest element. This is the
/// right shape for instrumentation: you record a continuous stream of samples but
/// only ever care about the most recent `capacity` of them, and you never want the
/// buffer itself to grow without bound on a hot path.
///
/// Every read is bounds-checked and there are no force-unwraps: a misconfigured
/// capacity degrades to a size of 1 rather than trapping at runtime.
public struct RingBuffer<Element> {
    private var storage: [Element?]
    private var head = 0     // index of the next write
    private var filled = 0   // number of valid elements (0...capacity)

    /// The maximum number of elements retained. Always >= 1.
    public let capacity: Int

    /// Creates a ring buffer. A non-positive `capacity` is clamped to 1 rather than
    /// trapping, so a bad configuration degrades instead of crashing in production.
    public init(capacity: Int) {
        let safeCapacity = max(1, capacity)
        self.capacity = safeCapacity
        self.storage = Array(repeating: nil, count: safeCapacity)
    }

    /// Number of elements currently stored.
    public var count: Int { filled }

    /// Whether the buffer holds no elements.
    public var isEmpty: Bool { filled == 0 }

    /// Appends an element in O(1), overwriting the oldest if already at capacity.
    public mutating func append(_ element: Element) {
        storage[head] = element
        head = (head + 1) % capacity
        filled = Swift.min(filled + 1, capacity)
    }

    /// The stored elements in insertion order (oldest first).
    public var elements: [Element] {
        guard filled > 0 else { return [] }
        var result = [Element]()
        result.reserveCapacity(filled)
        // Oldest element: at index 0 while the buffer is still filling; once full,
        // the oldest sample sits exactly where `head` is about to overwrite next.
        let start = filled < capacity ? 0 : head
        for offset in 0..<filled {
            let index = (start + offset) % capacity
            if let value = storage[index] {
                result.append(value)
            }
        }
        return result
    }

    /// Removes all elements while keeping the configured capacity.
    public mutating func removeAll() {
        storage = Array(repeating: nil, count: capacity)
        head = 0
        filled = 0
    }
}
