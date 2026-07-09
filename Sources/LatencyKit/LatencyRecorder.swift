import Foundation

/// A fixed-memory recorder for latency (or any `Double`) samples that reports
/// rolling percentiles over the most recent `capacity` observations.
///
/// Built for the hot path: ``record(_:)`` is O(1) and allocation-free, so you can
/// call it on every frame, every network round-trip, or every scroll tick without
/// the instrumentation distorting what it measures. Percentile queries are
/// O(n log n) over a snapshot — cheap in practice because you read them once per
/// HUD refresh, not once per sample.
public struct LatencyRecorder {
    private var buffer: RingBuffer<Double>

    /// The rolling window size (number of most-recent samples retained).
    public var capacity: Int { buffer.capacity }

    /// Creates a recorder retaining the most recent `capacity` samples.
    public init(capacity: Int) {
        self.buffer = RingBuffer(capacity: capacity)
    }

    /// Records one sample in O(1).
    ///
    /// Non-finite samples (`NaN`/`inf`) are ignored so a single bad measurement
    /// can't poison every percentile that follows it.
    public mutating func record(_ sample: Double) {
        guard sample.isFinite else { return }
        buffer.append(sample)
    }

    /// Number of samples currently inside the rolling window.
    public var count: Int { buffer.count }

    /// A snapshot summary of the current window, or `nil` if no samples exist.
    public func snapshot() -> Summary? {
        let values = buffer.elements
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0, +)
        return Summary(
            count: values.count,
            min: values.min() ?? 0,
            max: values.max() ?? 0,
            mean: total / Double(values.count),
            p50: PercentileCalculator.percentile(50, of: values) ?? 0,
            p90: PercentileCalculator.percentile(90, of: values) ?? 0,
            p99: PercentileCalculator.percentile(99, of: values) ?? 0
        )
    }

    /// Clears every recorded sample, keeping the configured capacity.
    public mutating func reset() { buffer.removeAll() }

    /// An immutable summary of a latency window.
    public struct Summary: Equatable {
        public let count: Int
        public let min: Double
        public let max: Double
        public let mean: Double
        public let p50: Double
        public let p90: Double
        public let p99: Double

        public init(count: Int, min: Double, max: Double, mean: Double,
                    p50: Double, p90: Double, p99: Double) {
            self.count = count
            self.min = min
            self.max = max
            self.mean = mean
            self.p50 = p50
            self.p90 = p90
            self.p99 = p99
        }
    }
}
