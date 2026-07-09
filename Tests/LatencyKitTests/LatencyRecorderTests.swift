import XCTest
@testable import LatencyKit

final class LatencyRecorderTests: XCTestCase {

    func testEmptyRecorderHasNilSnapshot() {
        let recorder = LatencyRecorder(capacity: 8)
        XCTAssertEqual(recorder.count, 0)
        XCTAssertNil(recorder.snapshot())
    }

    func testSummaryOnKnownData() throws {
        var recorder = LatencyRecorder(capacity: 16)
        [10.0, 20, 30, 40, 50, 60, 70, 80, 90, 100].forEach { recorder.record($0) }
        let summary = try XCTUnwrap(recorder.snapshot())
        XCTAssertEqual(summary.count, 10)
        XCTAssertEqual(summary.min, 10)
        XCTAssertEqual(summary.max, 100)
        XCTAssertEqual(summary.mean, 55)
        XCTAssertEqual(summary.p50, 50)
        XCTAssertEqual(summary.p90, 90)
        XCTAssertEqual(summary.p99, 100)
    }

    // The rolling window is the whole point: old spikes must age out of the
    // percentiles, not linger forever.
    func testRollingWindowEvictsOldSamplesFromPercentiles() {
        var recorder = LatencyRecorder(capacity: 3)
        [1.0, 2, 3, 4, 5].forEach { recorder.record($0) }
        let summary = try! XCTUnwrap(recorder.snapshot())
        XCTAssertEqual(summary.count, 3)
        XCTAssertEqual(summary.min, 3)
        XCTAssertEqual(summary.max, 5)
        XCTAssertEqual(summary.p50, 4)
    }

    func testNonFiniteSamplesAreIgnored() {
        var recorder = LatencyRecorder(capacity: 8)
        recorder.record(.nan)
        recorder.record(.infinity)
        recorder.record(-.infinity)
        recorder.record(5)
        XCTAssertEqual(recorder.count, 1)
        let summary = try! XCTUnwrap(recorder.snapshot())
        XCTAssertEqual(summary.p50, 5)
        XCTAssertEqual(summary.p99, 5)
    }

    func testResetClearsSamples() {
        var recorder = LatencyRecorder(capacity: 4)
        [1.0, 2, 3].forEach { recorder.record($0) }
        recorder.reset()
        XCTAssertEqual(recorder.count, 0)
        XCTAssertNil(recorder.snapshot())
    }

    // A performance guardrail on the hot path: recording a large burst of samples
    // must stay cheap and allocation-light. This is the "measure it" half of the
    // discipline, expressed as a test that fails if the fast path regresses.
    func testRecordThroughputIsCheap() {
        var recorder = LatencyRecorder(capacity: 512)
        measure {
            for i in 0..<50_000 { recorder.record(Double(i % 250)) }
        }
        XCTAssertEqual(recorder.count, 512)
    }
}
