import SwiftUI
import SwiftData

struct SegmentEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]

    let date: Date
    let segment: WorkSegment?

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedProject: Project?
    @State private var showValidationError = false
    @State private var validationMessage = ""

    var isEditing: Bool { segment != nil }

    init(date: Date, segment: WorkSegment?) {
        self.date = date
        self.segment = segment

        let cal = Calendar.zurich
        if let segment = segment {
            _startTime = State(initialValue: segment.startTime)
            _endTime = State(initialValue: segment.endTime)
            _selectedProject = State(initialValue: segment.project)
        } else {
            let dayStart = cal.startOfDay(for: date)
            _startTime = State(initialValue: cal.date(byAdding: .hour, value: 9, to: dayStart)!)
            _endTime = State(initialValue: cal.date(byAdding: .hour, value: 17, to: dayStart)!)
            _selectedProject = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Time Entry" : "New Time Entry")
                .font(.headline)

            Text(date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                .foregroundStyle(.secondary)

            Form {
                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)

                HStack {
                    Text("Project")
                    Spacer()
                    ComboBoxPicker(projects: projects, selection: $selectedProject)
                        .frame(width: 180)
                }

                if startTime < endTime {
                    let hours = endTime.timeIntervalSince(startTime) / 3600
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatHours(hours))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 360)
        .onAppear {
            // Default to "Other" project if none selected
            if selectedProject == nil {
                selectedProject = getOrCreateOtherProject()
            }
        }
        .alert("Invalid Entry", isPresented: $showValidationError) {
            Button("OK") {}
        } message: {
            Text(validationMessage)
        }
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
        let project = selectedProject ?? getOrCreateOtherProject()

        guard endTime > startTime else {
            validationMessage = "End time must be after start time."
            showValidationError = true
            return
        }

        if let segment = segment {
            segment.startTime = startTime
            segment.endTime = endTime
            segment.project = project
            segment.recalculateDuration()
        } else {
            let newSegment = WorkSegment(date: date, startTime: startTime, endTime: endTime, project: project)
            modelContext.insert(newSegment)
        }

        dismiss()
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }
}
