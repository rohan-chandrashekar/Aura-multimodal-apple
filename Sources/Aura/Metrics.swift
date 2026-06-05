import Foundation

enum Metrics {

    struct LatencyStats {
        let mean: Double
        let median: Double
        let p95: Double
        let min: Double
        let max: Double
        let count: Int
    }

    static func wordErrorRate(reference: String, hypothesis: String) -> Double {
        let ref = normalize(reference)
        let hyp = normalize(hypothesis)

        if ref.isEmpty { return hyp.isEmpty ? 0.0 : 1.0 }

        let m = ref.count
        let n = hyp.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                if ref[i - 1] == hyp[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = 1 + Swift.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
                }
            }
        }

        return Double(dp[m][n]) / Double(m)
    }

    static func latencyStats(_ values: [Double]) -> LatencyStats {
        guard !values.isEmpty else {
            return LatencyStats(mean: 0, median: 0, p95: 0, min: 0, max: 0, count: 0)
        }
        let sorted = values.sorted()
        let count = sorted.count
        let sum = sorted.reduce(0, +)

        let medianIndex = count / 2
        let median = count % 2 == 0
            ? (sorted[medianIndex - 1] + sorted[medianIndex]) / 2.0
            : sorted[medianIndex]

        let p95Index = Int(Double(count - 1) * 0.95)

        return LatencyStats(
            mean: sum / Double(count),
            median: median,
            p95: sorted[p95Index],
            min: sorted[0],
            max: sorted[count - 1],
            count: count
        )
    }

    private static func normalize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
