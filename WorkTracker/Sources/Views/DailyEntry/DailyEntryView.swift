import SwiftUI
import SwiftData

struct DailyEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkSegment.startTime) private var allSegments: [WorkSegment]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var selectedDate = Date()
    @State private var showAddSheet = false
    @State private var editingSegment: WorkSegment?

    private var segmentsForDate: [WorkSegment] {
        let dayStart = selectedDate.startOfDayZurich
        return allSegments.filter { $0.date.isSameDay(as: dayStart) }
            .sorted { $0.startTime < $1.startTime }
    }

    private var dailyTotal: Double {
        segmentsForDate.reduce(0) { $0 + $1.durationHours }
    }

    private let calculator = WorkHoursCalculator()
    private var daySummary: DaySummary {
        calculator.classify(date: selectedDate, vacationLookup: [:])
    }

    /// The current week (Mon-Fri) containing the selected date
    private var currentWeekDays: [Date] {
        let cal = Calendar.zurich
        let weekday = cal.component(.weekday, from: selectedDate) // 1=Sun, 2=Mon, ..., 7=Sat
        let daysFromMonday = (weekday + 5) % 7 // Mon=0, Tue=1, ..., Sun=6
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else { return [] }
        return (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left panel
            VStack(spacing: 0) {
                // Calendar
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Week at a glance
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    VStack(spacing: 2) {
                        ForEach(currentWeekDays, id: \.self) { day in
                            weekDayRow(day)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Day info
                VStack(alignment: .leading, spacing: 6) {
                    if daySummary.isHoliday, let name = daySummary.holidayName {
                        HStack(spacing: 6) {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(.orange)
                            Text(daySummary.isHalfDayHoliday ? "\(name) (half day)" : name)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                    }

                    if selectedDate.isWeekend {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.purple)
                            Text("Weekend")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()
            }
            .frame(width: 260)

            Divider()

            // Right: Time entries
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.title2.bold())

                        HStack(spacing: 12) {
                            Label(formatHours(dailyTotal), systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            if daySummary.expectedHours > 0 {
                                Text("of \(formatHours(daySummary.expectedHours)) expected")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .keyboardShortcut("n", modifiers: .command)
                    .help("Add a time entry (⌘N)")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Progress bar
                if daySummary.expectedHours > 0 {
                    let progress = min(dailyTotal / daySummary.expectedHours, 1.5)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.primary.opacity(0.08))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(dailyTotal >= daySummary.expectedHours ? .green : .blue)
                                .frame(width: geo.size.width * min(progress, 1.0))
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                Divider()
                    .padding(.horizontal, 24)

                // Segments
                if segmentsForDate.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 36))
                            .foregroundStyle(.quaternary)
                        Text("No time entries yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Click \"Add Entry\" to log your work")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(segmentsForDate) { segment in
                                SegmentRowView(segment: segment) {
                                    editingSegment = segment
                                } onDelete: {
                                    modelContext.delete(segment)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Daily Entry")
        .sheet(isPresented: $showAddSheet) {
            SegmentEditSheet(date: selectedDate, segment: nil)
        }
        .sheet(item: $editingSegment) { segment in
            SegmentEditSheet(date: selectedDate, segment: segment)
        }
    }

    // MARK: - Week Day Row

    private func weekDayRow(_ day: Date) -> some View {
        let isSelected = day.isSameDay(as: selectedDate)
        let isToday = day.isSameDay(as: Date())
        let daySegments = allSegments.filter { $0.date.isSameDay(as: day) }
        let dayHours = daySegments.reduce(0.0) { $0 + $1.durationHours }
        let dayCls = calculator.classify(date: day, vacationLookup: [:])

        return Button {
            selectedDate = day
        } label: {
            HStack(spacing: 8) {
                Text(day, format: .dateTime.weekday(.abbreviated))
                    .font(.caption)
                    .frame(width: 28, alignment: .leading)
                    .foregroundStyle(isToday ? .blue : .secondary)

                Text(day, format: .dateTime.day())
                    .font(.caption.monospacedDigit())
                    .frame(width: 20, alignment: .trailing)

                // Mini progress bar
                GeometryReader { geo in
                    let expected = dayCls.expectedHours
                    let progress = expected > 0 ? min(dayHours / expected, 1.0) : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.primary.opacity(0.06))
                        if dayHours > 0 {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(dayHours >= expected ? .green : .blue)
                                .frame(width: max(geo.size.width * progress, 2))
                        }
                    }
                }
                .frame(height: 3)

                Text(dayHours > 0 ? formatHoursCompact(dayHours) : "–")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(dayHours > 0 ? .primary : .quaternary)
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }

    private func formatHoursCompact(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        if m == 0 { return "\(h)h" }
        return String(format: "%d:%02d", h, m)
    }
}
