import Foundation

/// Shared formatting for hours and day counts, so every view renders durations the
/// same way. Rounds to whole minutes (fixing the old per-view bug where 7.999h showed
/// as "7h 60m").
enum TimeFormatting {
    /// e.g. `8h 05m`. Pass a non-negative magnitude (callers use `abs` for balances).
    static func hours(_ hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        return String(format: "%dh %02dm", totalMinutes / 60, abs(totalMinutes % 60))
    }

    /// e.g. `8h` or `8:05` — compact for tight rows.
    static func hoursCompact(_ hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = abs(totalMinutes % 60)
        return m == 0 ? "\(h)h" : String(format: "%d:%02d", h, m)
    }

    /// e.g. `1` or `1.5` — whole numbers stay integers, halves get one decimal.
    static func days(_ days: Double) -> String {
        days == days.rounded() ? "\(Int(days))" : String(format: "%.1f", days)
    }
}
