import SwiftUI
import SwiftData

struct SegmentEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]
    @Query(sort: \WorkSegment.startTime) private var allSegments: [WorkSegment]

    let segment: WorkSegment?

    @State private var entryDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedProject: Project?

    var isEditing: Bool { segment != nil }

    /// `suggestedStart` is the auto-filled start for a NEW entry — the end of the day's
    /// last segment, or 08:10 when the day is empty (computed by the caller). Ignored
    /// when editing an existing segment.
    init(date: Date, segment: WorkSegment?, suggestedStart: Date? = nil) {
        self.segment = segment

        let cal = Calendar.zurich
        if let segment {
            _entryDate = State(initialValue: segment.date)
            _startTime = State(initialValue: segment.startTime)
            _endTime = State(initialValue: segment.endTime)
            _selectedProject = State(initialValue: segment.project)
        } else {
            let start = suggestedStart
                ?? cal.date(bySettingHour: 8, minute: 10, second: 0, of: date)
                ?? cal.startOfDay(for: date)
            _entryDate = State(initialValue: cal.startOfDay(for: date))
            _startTime = State(initialValue: start)
            _endTime = State(initialValue: start.addingTimeInterval(3600))  // +1h default
            _selectedProject = State(initialValue: nil)
        }
    }

    /// Other segments on the same day (the one being edited is excluded).
    private var sameDayConflicts: [WorkSegment] {
        let editingID = segment?.persistentModelID
        return allSegments.filter {
            $0.persistentModelID != editingID && $0.date.isSameDay(as: entryDate)
        }
    }

    /// First blocking problem with the current input, or nil when it's valid.
    private var validationError: String? {
        guard endTime > startTime else { return tr("End time must be after start time.") }
        guard startTime.isSameDay(as: endTime) else {
            return tr("An entry can’t cross midnight — split it into two entries.")
        }
        if let clash = sameDayConflicts.first(where: { startTime < $0.endTime && endTime > $0.startTime }) {
            return tr("Overlaps with %@–%@.", TimeField.format(clash.startTime), TimeField.format(clash.endTime))
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? tr("Edit Time Entry") : tr("New Time Entry"))
                .font(.headline)

            Form {
                LabeledContent(tr("Start")) {
                    TimeField(time: $startTime, date: entryDate, autoFocus: true)
                        .frame(width: 72)
                }
                LabeledContent(tr("End")) {
                    TimeField(time: $endTime, date: entryDate)
                        .frame(width: 72)
                }

                HStack {
                    Text(tr("Project"))
                    Spacer()
                    ComboBoxPicker(projects: projects, selection: $selectedProject,
                                   onCreate: { createProject(named: $0) })
                        .frame(width: 180)
                }

                // Date lives below the entry fields so it doesn't interrupt the
                // Start → End → Project flow (it's usually already the selected day).
                DatePicker(tr("Date"), selection: $entryDate, displayedComponents: .date)
                    .onChange(of: entryDate) { _, newDay in
                        startTime = reanchor(startTime, to: newDay)
                        endTime = reanchor(endTime, to: newDay)
                    }

                if let error = validationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    let hours = endTime.timeIntervalSince(startTime) / 3600
                    HStack {
                        Text(tr("Duration"))
                        Spacer()
                        Text(TimeFormatting.hours(hours))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(tr("Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? tr("Save") : tr("Add")) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(validationError != nil)
            }

            // Save from anywhere in the sheet (⌘↩), even while a text field or the
            // project picker has focus. Hidden — the visible button handles plain Return.
            Button("") { save() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(validationError != nil)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .padding()
        .frame(width: 380)
        .onAppear {
            // Default to "Other" project if none selected
            if selectedProject == nil {
                selectedProject = getOrCreateOtherProject()
            }
        }
    }

    // MARK: - Helpers

    /// Move a time onto `day`, preserving its hour and minute.
    private func reanchor(_ time: Date, to day: Date) -> Date {
        let comps = Calendar.zurich.dateComponents([.hour, .minute], from: time)
        return Calendar.zurich.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0,
                                    second: 0, of: day) ?? time
    }

    private func createProject(named name: String) -> Project {
        if let existing = projects.first(where: {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing
        }
        let project = Project(name: name)
        modelContext.insert(project)
        return project
    }

    private func getOrCreateOtherProject() -> Project {
        if let existing = projects.first(where: { $0.name == "Other" }) {
            return existing
        }
        let other = Project(name: "Other")
        modelContext.insert(other)
        return other
    }

    private func save() {
        guard validationError == nil else { return }
        let project = selectedProject ?? getOrCreateOtherProject()

        if let segment {
            segment.date = entryDate.startOfDayZurich
            segment.startTime = startTime
            segment.endTime = endTime
            segment.project = project
            segment.recalculateDuration()
        } else {
            let newSegment = WorkSegment(date: entryDate, startTime: startTime,
                                         endTime: endTime, project: project)
            modelContext.insert(newSegment)
        }

        dismiss()
    }
}
