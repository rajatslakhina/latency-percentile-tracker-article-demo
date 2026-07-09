import XCTest
@testable import LatencyKit

final class RingBufferTests: XCTestCase {

    func testEmptyBufferReportsEmptyState() {
        let buffer = RingBuffer<Int>(capacity: 4)
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.elements, [])
    }

    func testAppendBelowCapacityPreservesOrder() {
        var buffer = RingBuffer<Int>(capacity: 4)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertFalse(buffer.isEmpty)
        XCTAssertEqual(buffer.elements, [1, 2, 3])
    }

    func testAppendAtExactCapacityKeepsEverything() {
        var buffer = RingBuffer<Int>(capacity: 3)
        [1, 2, 3].forEach { buffer.append($0) }
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.elements, [1, 2, 3])
    }

    // The eviction-order invariant is the bug that actually ships: once full, the
    // oldest sample must be the one that disappears, and order must stay intact.
    func testAppendBeyondCapacityEvictsOldestInOrder() {
        var buffer = RingBuffer<Int>(capacity: 3)
        [1, 2, 3, 4, 5].forEach { buffer.append($0) }
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.elements, [3, 4, 5])
    }

    func testWraparoundStaysCorrectAcrossManyAppends() {
        var buffer = RingBuffer<Int>(capacity: 3)
        for value in 1...100 { buffer.append(value) }
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.elements, [98, 99, 100])
    }

    func testNonPositiveCapacityIsClampedNotTrapped() {
        let zero = RingBuffer<Int>(capacity: 0)
        XCTAssertEqual(zero.capacity, 1)
        let negative = RingBuffer<Int>(capacity: -7)
        XCTAssertEqual(negative.capacity, 1)

        var single = RingBuffer<Int>(capacity: 0)
        single.append(10)
        single.append(20)
        XCTAssertEqual(single.elements, [20])
    }

    func testRemoveAllResetsButKeepsCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        [1, 2, 3, 4].forEach { buffer.append($0) }
        buffer.removeAll()
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.elements, [])
        XCTAssertEqual(buffer.capacity, 3)
        buffer.append(99)
        XCTAssertEqual(buffer.elements, [99])
    }
}
