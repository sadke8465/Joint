import Foundation

/// The ordering rule, extracted from the view so it can be reasoned about — and tested —
/// without SwiftUI in the way.
///
/// The property that matters for multiple taps: the arrangement is a pure function of *which*
/// rows are settled, never of the order they were tapped or of how their animations
/// interleaved. Two taps in either order converge on the same list, so the list cannot end up
/// sorted twice or sorted wrongly no matter how the timing falls.
enum ReorderPlanner {
    /// Incomplete rows first, then settled rows, each block keeping the list's natural order.
    /// Only rows in `laidOut` occupy a slot, so a filter is a third input to the same pure
    /// function — and every convergence property survives it unchanged.
    static func slots(
        ids: [String],
        laidOut: Set<String>,
        settled: Set<String>
    ) -> [String: Int] {
        var result: [String: Int] = [:]
        var index = 0
        let present = ids.filter { laidOut.contains($0) }
        for id in present where !settled.contains(id) {
            result[id] = index
            index += 1
        }
        for id in present where settled.contains(id) {
            result[id] = index
            index += 1
        }
        return result
    }

    static func slots(ids: [String], settled: Set<String>) -> [String: Int] {
        slots(ids: ids, laidOut: Set(ids), settled: settled)
    }

    /// Rows whose slot differs between two arrangements.
    static func moved(from previous: [String: Int], to next: [String: Int]) -> [String] {
        next.keys.filter { previous[$0] != next[$0] }
    }
}
