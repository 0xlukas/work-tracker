import SwiftUI

struct MonthlyBreakdownView: View {
    let months: [MonthSummary]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Month")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                Text("Expected")
                    .frame(width: 72, alignment: .trailing)
                Text("Worked")
                    .frame(width: 72, alignment: .trailing)
                Text("Balance")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                HStack {
                    Text(month.monthName)
                        .frame(width: 100, alignment: .leading)

                    // Mini progress bar
                    GeometryReader { geo in
                        let target = month.expectedHours
                        let progress = target > 0 ? min(month.actualHours / target, 1.5) : 0
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.primary.opacity(0.06))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor(month))
                                .frame(width: geo.size.width * min(progress, 1.0))
                        }
                    }
                    .frame(height: 4)

                    Text(formatHours(month.expectedHours))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 72, alignment: .trailing)
                    Text(formatHours(month.actualHours))
                        .monospacedDigit()
                        .frame(width: 72, alignment: .trailing)
                    Text("\(month.balance >= 0 ? "+" : "")\(formatHours(abs(month.balance)))")
                        .monospacedDigit()
                        .foregroundColor(balanceColor(month))
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    index % 2 == 0
                        ? Color.clear
                        : Color.primary.opacity(0.02)
                )
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.03)))
    }

    private func progressColor(_ month: MonthSummary) -> Color {
        if month.actualHours == 0 { return .clear }
        if month.actualHours >= month.expectedHours { return .green }
        return .blue
    }

    private func balanceColor(_ month: MonthSummary) -> Color {
        if month.actualHours == 0 && month.expectedHours == 0 { return .secondary }
        return month.balance >= 0 ? .green : .red
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }
}
