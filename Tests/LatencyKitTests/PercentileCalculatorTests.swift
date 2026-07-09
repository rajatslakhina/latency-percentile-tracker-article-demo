import XCTest
@testable import LatencyKit

final class PercentileCalculatorTests: XCTestCase {

    func testEmptyInputReturnsNil() {
        XCTAssertNil(PercentileCalculator.percentile(50, of: []))
    }

    func testSingleSampleReturnsThatSampleForAnyPercentile() {
        XCTAssertEqual(PercentileCalculator.percentile(0, of: [42]), 42)
        XCTAssertEqual(PercentileCalculator.percentile(50, of: [42]), 42)
        XCTAssertEqual(PercentileCalculator.percentile(99, of: [42]), 42)
        XCTAssertEqual(PercentileCalculator.percentile(100, of: [42]), 42)
    }

    func testKnownDatasetNearestRank() {
        let data = [10.0, 20, 30, 40, 50, 60, 70, 80, 90, 100]
        XCTAssertEqual(PercentileCalculator.percentile(0, of: data), 10)
        XCTAssertEqual(PercentileCalculator.percentile(50, of: data), 50)
        XCTAssertEqual(PercentileCalculator.percentile(90, of: data), 90)
        XCTAssertEqual(PercentileCalculator.percentile(99, of: data), 100)
        XCTAssertEqual(PercentileCalculator.percentile(100, of: data), 100)
    }

    func testUnsortedInputIsHandled() {
        let data = [30.0, 10, 20]
        XCTAssertEqual(PercentileCalculator.percentile(50, of: data), 20)
    }

    // Out-of-range percentiles are clamped, not treated as programmer error.
    func testPercentileOutOfRangeIsClamped() {
        let data = [10.0, 20, 30]
        XCTAssertEqual(PercentileCalculator.percentile(-25, of: data), 10)
        XCTAssertEqual(PercentileCalculator.percentile(250, of: data), 30)
    }
}
