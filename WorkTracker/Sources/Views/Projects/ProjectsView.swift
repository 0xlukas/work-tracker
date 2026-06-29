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
    @State private var projectPendingDelete: Project?

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
                    Text(tr("Projects"))
                        .font(.title2.bold())
                    Text(tr(projects.count == 1 ? "%lld project" : "%lld projects", projects.count))
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
                    TextField(tr("Add new project..."), text: $newProjectName)
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
                    Text(tr("Time Report"))
                        .font(.title2.bold())
                    Text(tr("Hours per project"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Date range
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text(tr("From"))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        DatePicker("", selection: $reportFrom, displayedComponents: .date)
                            .labelsHidden()
                    }
                    HStack(spacing: 8) {
                        Text(tr("To"))
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
                        Text(tr("No work logged in this period"))
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
                            Text(tr("Total"))
                                .font(.subheadline.bold())
                            Spacer()
                            Text(TimeFormatting.hours(totalHours))
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
        .navigationTitle(tr("Projects"))
        .alert(tr("Cannot Delete"), isPresented: $showDeleteError) {
            Button(tr("OK")) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .confirmationDialog(
            tr("Delete this project?"),
            isPresented: Binding(
                get: { projectPendingDelete != nil },
                set: { if !$0 { projectPendingDelete = nil } }
            ),
            presenting: projectPendingDelete
        ) { project in
            Button(tr("Delete"), role: .destructive) {
                modelContext.delete(project)
                projectPendingDelete = nil
            }
            Button(tr("Cancel"), role: .cancel) { projectPendingDelete = nil }
        } message: { project in
            Text(tr("'%@' will be removed.", project.name))
        }
    }

    // MARK: - Project Row

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        if editingProject?.id == project.id {
            HStack(spacing: 8) {
                TextField(tr("Project name"), text: $editName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveEdit(project) }
                Button(tr("Save")) { saveEdit(project) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button(tr("Cancel")) { editingProject = nil }
                    .controlSize(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        } else {
            HStack(spacing: 12) {
                Circle()
                    .fill(projectColor(project).opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(project.name.prefix(1)).uppercased())
                            .font(.subheadline.bold())
                            .foregroundStyle(projectColor(project))
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name)
                        .font(.body)
                    Text(tr(project.segments.count == 1 ? "%lld entry" : "%lld entries", project.segments.count))
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
                        .help(tr("Rename project"))
                        .accessibilityLabel(tr("Rename project"))

                        Button { requestDelete(project) } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help(tr("Delete project"))
                        .accessibilityLabel(tr("Delete project"))
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
            .contentShape(Rectangle())
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredProject = isHovered ? project : nil
                }
            }
            .onTapGesture(count: 2) {
                editingProject = project
                editName = project.name
            }
            .contextMenu {
                Button {
                    editingProject = project
                    editName = project.name
                } label: { Label(tr("Rename"), systemImage: "pencil") }
                Button(role: .destructive) { requestDelete(project) } label: {
                    Label(tr("Delete"), systemImage: "trash")
                }
            }
        }
    }

    private func projectColor(_ project: Project) -> Color {
        let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo, .red, .mint, .cyan]
        let sum = project.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }

    // MARK: - Report Row

    private func reportRow(item: ProjectHours, maxHours: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.project.name)
                    .font(.subheadline)
                Spacer()
                Text(TimeFormatting.hours(item.hours))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(projectColor(item.project).opacity(0.2))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(projectColor(item.project))
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

    private func requestDelete(_ project: Project) {
        if project.segments.isEmpty {
            projectPendingDelete = project
        } else {
            deleteErrorMessage = tr("'%@' has %lld time entries. Delete or reassign them first.", project.name, project.segments.count)
            showDeleteError = true
        }
    }

}
