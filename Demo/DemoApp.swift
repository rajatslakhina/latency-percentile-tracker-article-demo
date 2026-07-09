import SwiftUI
import LatencyKit

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            LatencyDashboardView()
        }
    }
}

/// A tiny live dashboard over ``LatencyRecorder``.
///
/// Tap "Record a burst" to push a batch of simulated latency samples (a realistic
/// mix: a fast baseline plus an occasional tail spike) through the recorder, and
/// watch p50/p90/p99 update over a fixed rolling window. The point the demo makes
/// visually: the mean barely moves when a spike lands, but p99 jumps — which is
/// exactly why you instrument tails, not averages.
struct LatencyDashboardView: View {
    @State private var recorder = LatencyRecorder(capacity: 200)
    @State private var summary: LatencyRecorder.Summary?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let summary {
                    statGrid(summary)
                    tailBar(summary)
                } else {
                    ContentUnavailablePlaceholder()
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        recordBurst(includingSpike: false)
                    } label: {
                        Label("Record a calm burst", systemImage: "waveform.path")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        recordBurst(includingSpike: true)
                    } label: {
                        Label("Record a burst with a tail spike", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        recorder.reset()
                        summary = recorder.snapshot()
                    } label: {
                        Label("Reset window", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Latency HUD")
        }
    }

    private func recordBurst(includingSpike: Bool) {
        for _ in 0..<40 {
            // A tight baseline around 18ms.
            recorder.record(Double.random(in: 12...26))
        }
        if includingSpike {
            // A handful of tail-latency spikes that a mean would happily hide.
            for _ in 0..<3 {
                recorder.record(Double.random(in: 180...320))
            }
        }
        summary = recorder.snapshot()
    }

    @ViewBuilder
    private func statGrid(_ s: LatencyRecorder.Summary) -> some View {
        let items: [(String, String)] = [
            ("Samples", "\(s.count)"),
            ("Mean", format(s.mean)),
            ("p50", format(s.p50)),
            ("p90", format(s.p90)),
            ("p99", format(s.p99)),
            ("Max", format(s.max))
        ]
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                  spacing: 16) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.1)
                        .font(.title3.monospacedDigit().weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func tailBar(_ s: LatencyRecorder.Summary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mean vs. p99")
                .font(.subheadline.weight(.semibold))
            bar(label: "Mean", value: s.mean, reference: s.max, tint: .green)
            bar(label: "p99", value: s.p99, reference: s.max, tint: .red)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func bar(label: String, value: Double, reference: Double, tint: Color) -> some View {
        let fraction = reference > 0 ? Swift.min(1, value / reference) : 0
        HStack {
            Text(label).font(.caption.monospaced()).frame(width: 44, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 6)
                    .fill(tint.opacity(0.85))
                    .frame(width: geo.size.width * fraction)
            }
            .frame(height: 18)
            Text(format(value)).font(.caption.monospaced()).frame(width: 64, alignment: .trailing)
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.0f ms", value)
    }
}

private struct ContentUnavailablePlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No samples yet")
                .font(.headline)
            Text("Record a burst to populate the rolling window.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
}
