import Foundation

/// Computes percentiles using the nearest-rank method.
///
/// Nearest-rank is a deliberate choice over linear interpolation: it always
/// returns a value that actually occurred in the sample set. That makes the
/// numbers defensible in review ("p99 = 214ms" is a real request that happened,
/// not an interpolated fiction) and removes an entire class of off-by-one
/// interpolation bugs from the test surface.
public enum PercentileCalculator {

    /// Returns the value at the given percentile using the nearest-rank method.
    ///
    /// - Parameters:
    ///   - p: The percentile in the range 0...100. Values outside the range are
    ///     clamped rather than treated as programmer error.
    ///   - samples: The observations. Order does not matter; the input is sorted
    ///     internally.
    /// - Returns: The nearest-rank value, or `nil` for an empty input.
    public static func percentile(_ p: Double, of samples: [Double]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let sorted = samples.sorted()
        let clampedP = Swift.min(100, Swift.max(0, p))
        if clampedP <= 0 { return sorted.first }
        // Nearest-rank: rank = ceil(p/100 * n), 1-based, then convert to a
        // 0-based index and clamp into the valid range as belt-and-suspenders.
        let rank = Int((clampedP / 100.0 * Double(sorted.count)).rounded(.up))
        let index = Swift.min(Swift.max(rank - 1, 0), sorted.count - 1)
        return sorted[index]
    }
}
