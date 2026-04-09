import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @Query(sort: \WorkSegment.startTime) private var allSegments: [WorkSegment]

    @State private var newProjectName = ""
    @State private var editingProject: Project?
    @State private var editName = ""
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var hoveredProject: Project?

    @State private var reportFrom: Date = Calendar.zurich.date(from: DateComponents(
        timeZone: TimeZone(identifier: "Europe/Zurich"),
        year: Calendar.zurich.component(.year, from: Date()),
        month: 1, day: 1))!
    @State private var reportTo: Date = Date()

    private let calculator = WorkHoursCalculator()

    var body: some View {
        HStack(spacing: 0) {
            // Left: Projects
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projects")
                        .font(.title2.bold())
                    Text("\(projects.count) project\(projects.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(projects) { project in
                            projectRow(project)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                Divider()
                    .padding(.horizontal, 12)

                // Add project
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    TextField("Add new project...", text: $newProjectName)
                        .textFieldStyle(.plain)
                        .onSubmit { addProject() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .frame(minWidth: 300, idealWidth: 320)

            Divider()

            // Right: Time Report
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Report")
                        .font(.title2.bold())
                    Text("Hours per project")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Date range
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text("From")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        DatePicker("", selection: $reportFrom, displayedComponents: .date)
                            .labelsHidden()
                    }
                    HStack(spacing: 8) {
                        Text("To")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        DatePicker("", selection: $reportTo, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Divider()
                    .padding(.horizontal, 24)

                let breakdown = calculator.projectBreakdown(from: reportFrom, to: reportTo, segments: allSegments)

                if breakdown.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 32))
                            .foregroundStyle(.quaternary)
                        Text("No work logged in this period")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(breakdown) { item in
                                reportRow(item: item, maxHours: breakdown.map(\.hours).max() ?? 1)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        let totalHours = breakdown.reduce(0) { $0 + $1.hours }
                        HStack {
                            Text("Total")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(formatHours(totalHours))
                                .font(.body.bold().monospacedDigit())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(minWidth: 360)
        }
        .navigationTitle("Projects")
        .alert("Cannot Delete", isPresented: $showDeleteError) {
            Button("OK") {}
        } message: {
            Text(deleteErrorMessage)
        }
    }

    // MARK: - Project Row

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        if editingProject?.id == project.id {
            HStack(spacing: 8) {
                TextField("Project name", text: $editName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveEdit(project) }
                Button("Save") { saveEdit(project) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button("Cancel") { editingProject = nil }
                    .controlSize(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        } else {
            HStack(spacing: 12) {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(project.name.prefix(1)).uppercased())
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name)
                        .font(.body)
                    Text("\(project.segments.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if hoveredProject?.id == project.id {
                    HStack(spacing: 4) {
                        Button {
                            editingProject = project
                            editName = project.name
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)

                        Button { deleteProject(project) } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hoveredProject?.id == project.id ? Color.primary.opacity(0.05) : Color.clear)
            )
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredProject = isHovered ? project : nil
                }
            }
        }
    }

    // MARK: - Report Row

    private func reportRow(item: ProjectHours, maxHours: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.project.name)
                    .font(.subheadline)
                Spacer()
                Text(formatHours(item.hours))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.blue.opacity(0.2))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.blue)
                            .frame(width: geo.size.width * (item.hours / maxHours))
                    }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func addProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        modelContext.insert(Project(name: name))
        newProjectName = ""
    }

    private func saveEdit(_ project: Project) {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        project.name = name
        editingProject = nil
    }

    private func deleteProject(_ project: Project) {
        if project.segments.isEmpty {
            modelContext.delete(project)
        } else {
            deleteErrorMessage = "'\(project.name)' has \(project.segments.count) time entries. Delete or reassign them first."
            showDeleteError = true
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }
}
