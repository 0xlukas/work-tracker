import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    var body: some View {
        // Standard macOS Settings layout: a tab per topic, each a grouped form.
        TabView {
            Tab(tr("General"), systemImage: "gearshape") { GeneralSettings() }
            Tab(tr("Work"), systemImage: "briefcase") { WorkSettings() }
            Tab(tr("Storage"), systemImage: "externaldrive") { StorageSettings() }
            Tab(tr("Backups"), systemImage: "clock.arrow.circlepath") { BackupSettings() }
        }
        .frame(width: 600, height: 540)
    }
}

// MARK: - General

private struct GeneralSettings: View {
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section {
                Picker(tr("Language"), selection: $preferences.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section {
                Picker(tr("CSV format"), selection: $preferences.csvFormat) {
                    ForEach(CSVFormat.allCases) { Text($0.title).tag($0) }
                }
            } header: {
                Text(tr("Export"))
            } footer: {
                Text(tr("Excel with German regional settings expects semicolons and decimal commas."))
            }

            Section {
                Toggle(tr("Show an inspirational quote on launch"), isOn: $preferences.dailyQuoteEnabled)
            } header: {
                Text(tr("Daily Quote"))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Work: schedule, vacation, balances

private struct WorkSettings: View {
    @Environment(Preferences.self) private var preferences
    @State private var editingPeriod: WorkSchedule.Period?
    @State private var openingBalanceText = ""
    @State private var openingBalanceInvalid = false

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section {
                ForEach(Array(preferences.schedule.periods.enumerated()), id: \.element.id) { index, period in
                    periodRow(period, isFirst: index == 0)
                }
                Button {
                    let start = max(Date().startOfDayZurich, (preferences.schedule.periods.last?.effectiveFrom ?? .distantPast).addingDays(1))
                    var period = preferences.schedule.period(on: start)
                    period.id = UUID()
                    period.effectiveFrom = start
                    editingPeriod = period
                } label: {
                    Label(tr("Add Schedule Change…"), systemImage: "plus")
                }
            } header: {
                Text(tr("Work Schedule"))
            } footer: {
                Text(tr("Expected hours per weekday. Add a change when your contract changes — earlier balances keep the old schedule. Half-day holidays and half-day absences count half of that day's hours."))
            }

            Section {
                DatePicker(tr("Start date"), selection: $preferences.trackingStartDate, displayedComponents: .date)
                LabeledContent(tr("Opening balance")) {
                    HStack(spacing: 6) {
                        TextField("", text: $openingBalanceText, prompt: Text("+0:00"))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onSubmit(commitOpeningBalance)
                        Text(tr("hours")).foregroundStyle(.secondary)
                    }
                }
                if openingBalanceInvalid {
                    Text(tr("Enter hours like +12:30, -4:15 or 7.5."))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(tr("Tracking"))
            } footer: {
                Text(tr("Overtime (+) or undertime (−) carried in from before the start date. Added to the all-time balance."))
            }

            Section {
                Stepper(value: $preferences.vacationEntitlement, in: 0...60, step: 0.5) {
                    LabeledContent(tr("Annual vacation entitlement")) {
                        Text(TimeFormatting.dayCount(preferences.vacationEntitlement))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Toggle(tr("Carry unused days into the next year"), isOn: $preferences.carryOverVacation)
                Stepper(value: $preferences.openingVacationCarryOver, in: 0...60, step: 0.5) {
                    LabeledContent(tr("Carried into %@", String(preferences.trackingStartDate.zurichYear))) {
                        Text(TimeFormatting.dayCount(preferences.openingVacationCarryOver))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text(tr("Vacation"))
            } footer: {
                Text(tr("Vacation beyond a year's allowance gets no time credit — those days count as normal working days."))
            }
        }
        .formStyle(.grouped)
        .onAppear { openingBalanceText = TimeFormatting.signedClock(preferences.openingBalanceHours) }
        .onDisappear(perform: commitOpeningBalance)
        .sheet(item: $editingPeriod) { period in
            ScheduleEditor(period: period, isFirst: period.id == preferences.schedule.periods.first?.id,
                           fullTimeWeeklyHours: preferences.fullTimeWeeklyHours) { saved, fullTimeWeek in
                preferences.fullTimeWeeklyHours = fullTimeWeek
                preferences.schedule.upsert(saved)
            }
        }
    }

    private func periodRow(_ period: WorkSchedule.Period, isFirst: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(isFirst ? tr("Initial schedule") : tr("From %@", period.effectiveFrom.formatted(.app.day().month().year())))
                Text(scheduleSummary(period))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(tr("Edit…")) { editingPeriod = period }
                .controlSize(.small)
            if !isFirst {
                Button(role: .destructive) { preferences.schedule.remove(id: period.id) } label: {
                    Image(systemName: "trash")
                }
                .controlSize(.small)
                .help(tr("Remove this schedule change"))
            }
        }
    }

    private func scheduleSummary(_ period: WorkSchedule.Period) -> String {
        let percent = (period.workload(fullTimeWeeklyHours: preferences.fullTimeWeeklyHours) * 100).rounded()
        return tr("%@ per week (%@%%)", TimeFormatting.hoursCompact(period.weeklyHours), String(Int(percent)))
    }

    private func commitOpeningBalance() {
        if let value = TimeFormatting.parseSignedHours(openingBalanceText.isEmpty ? "0" : openingBalanceText) {
            preferences.openingBalanceHours = value
            openingBalanceText = TimeFormatting.signedClock(value)
            openingBalanceInvalid = false
        } else {
            openingBalanceInvalid = true
        }
    }
}

/// Edit one schedule period: hours per weekday, with a workload shortcut.
private struct ScheduleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var period: WorkSchedule.Period
    let isFirst: Bool
    @State var fullTimeWeeklyHours: Double
    /// Receives the edited period and the full-time reference week.
    let onSave: (WorkSchedule.Period, Double) -> Void
    @State private var workload = 100.0

    init(period: WorkSchedule.Period, isFirst: Bool, fullTimeWeeklyHours: Double,
         onSave: @escaping (WorkSchedule.Period, Double) -> Void) {
        _period = State(initialValue: period)
        self.isFirst = isFirst
        _fullTimeWeeklyHours = State(initialValue: fullTimeWeeklyHours)
        self.onSave = onSave
        _workload = State(initialValue: (period.workload(fullTimeWeeklyHours: fullTimeWeeklyHours) * 100).rounded())
    }

    private var weekdayNames: [String] {
        // Monday-first, in the UI language.
        let formatter = DateFormatter()
        formatter.locale = Localization.locale
        let symbols = formatter.standaloneWeekdaySymbols ?? []
        return (0..<7).map { symbols.isEmpty ? "\($0)" : symbols[($0 + 1) % 7].capitalized(with: Localization.locale) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isFirst {
                        LabeledContent(tr("Applies"), value: tr("From the start of tracking"))
                    } else {
                        DatePicker(tr("Applies from"), selection: $period.effectiveFrom, displayedComponents: .date)
                    }
                }

                Section {
                    ForEach(0..<7, id: \.self) { index in
                        Stepper(value: $period.hours[index], in: 0...14, step: 0.25) {
                            LabeledContent(weekdayNames[index]) {
                                Text(period.hours[index] == 0 ? tr("Off") : TimeFormatting.hours(period.hours[index]))
                                    .monospacedDigit()
                                    .foregroundStyle(period.hours[index] == 0 ? .tertiary : .secondary)
                            }
                        }
                    }
                    LabeledContent(tr("Per week"), value: TimeFormatting.hours(period.weeklyHours))
                } header: {
                    Text(tr("Hours per day"))
                }

                Section {
                    Stepper(value: $workload, in: 5...100, step: 5) {
                        LabeledContent(tr("Workload"), value: "\(Int(workload)) %")
                    }
                    Stepper(value: $fullTimeWeeklyHours, in: 20...50, step: 0.5) {
                        LabeledContent(tr("Full-time week"), value: TimeFormatting.hours(fullTimeWeeklyHours))
                    }
                    Button(tr("Spread Evenly over Monday–Friday")) {
                        let daily = fullTimeWeeklyHours / 5 * workload / 100
                        period.hours = [daily, daily, daily, daily, daily, 0, 0]
                    }
                } header: {
                    Text(tr("Part-time"))
                } footer: {
                    Text(tr("Sets each weekday to the workload's share of a full-time week. Adjust single days above afterwards."))
                }
            }
            .formStyle(.grouped)
            .navigationTitle(tr("Work Schedule"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        onSave(period, fullTimeWeeklyHours)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(width: 440, height: 560)
    }
}

// MARK: - Storage

private struct StorageSettings: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Preferences.self) private var preferences
    @Environment(BackupManager.self) private var backups

    /// A move waiting for the user's decision.
    private struct PendingMove: Identifiable {
        let id = UUID()
        let directory: URL
        let mirror: URL?
    }

    @State private var cloudChoice: URL?
    @State private var existingStoreMove: PendingMove?
    @State private var moveError: String?
    @State private var needsRestart = false

    private var currentDirectory: URL { StoreLocation.currentDirectory }
    private var isDefault: Bool { StoreLocation.customDirectory == nil }
    private var isCloud: Bool { StoreLocation.isCloudSynced(currentDirectory) }

    var body: some View {
        Form {
            if isCloud {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(tr("Your database is in a cloud-synced folder"), systemImage: "exclamationmark.icloud.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text(tr("Sync clients upload the database and its journal separately and can create conflicting copies, which can corrupt or lose data. Keep the database on this Mac and let the app copy verified backups into the cloud folder instead."))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button(tr("Move Database to This Mac & Back Up to This Folder")) {
                            requestMove(to: StoreLocation.defaultDirectory,
                                        mirror: currentDirectory.appendingPathComponent("Work Tracker Backups", isDirectory: true))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(isDefault ? tr("Default (Application Support)") : tr("Custom location"),
                              systemImage: isDefault ? "internaldrive" : "folder")
                            .font(.subheadline)
                        Text(currentDirectory.path)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button(tr("Choose Folder…")) { chooseFolder() }
                    if !isDefault {
                        Button(tr("Reset to Default")) { requestMove(to: StoreLocation.defaultDirectory, mirror: nil) }
                    }
                }
                .padding(.vertical, 2)
                Button(tr("Show in Finder")) { NSWorkspace.shared.activateFileViewerSelecting([StoreLocation.storeURL]) }
            } header: {
                Text(tr("Database Location"))
            } footer: {
                Text(tr("Moving copies a consistent snapshot of your data to the new folder and restarts the app. The old copy is left in place."))
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(tr("This folder is synced by a cloud service"), isPresented: Binding(
            get: { cloudChoice != nil }, set: { if !$0 { cloudChoice = nil } }
        ), presenting: cloudChoice) { folder in
            Button(tr("Keep Database Local & Back Up There")) {
                preferences.backupMirrorDirectory = folder
                Task { await backups.run(force: true) }
            }
            Button(tr("Store the Database There Anyway")) { requestMove(to: folder, mirror: nil) }
            Button(tr("Cancel"), role: .cancel) {}
        } message: { _ in
            Text(tr("A live database in a synced folder can be corrupted. Recommended: keep it on this Mac and copy backups to that folder."))
        }
        .confirmationDialog(tr("That folder already contains a Work Tracker database"), isPresented: Binding(
            get: { existingStoreMove != nil }, set: { if !$0 { existingStoreMove = nil } }
        ), presenting: existingStoreMove) { move in
            Button(tr("Replace It with the Current Data")) { performMove(move, policy: .replace) }
            Button(tr("Use the Data Already There")) { performMove(move, policy: .useExisting) }
            Button(tr("Cancel"), role: .cancel) {}
        } message: { move in
            let modified = DatabaseBackup.modificationDate(of: StoreLocation.storeURL(in: move.directory))?
                .formatted(.app.day().month().year().hour().minute()) ?? "–"
            Text(tr("The database there was last changed %@. Replacing it keeps the old file in Backups.", modified))
        }
        .alert(tr("Could not move the database"), isPresented: Binding(
            get: { moveError != nil }, set: { if !$0 { moveError = nil } }
        )) {
            Button(tr("OK")) {}
        } message: {
            Text(moveError ?? "")
        }
        .alert(tr("Restart Required"), isPresented: $needsRestart) {
            Button(tr("Restart Now")) {}
        } message: {
            Text(tr("Work Tracker restarts to use the new location. Changes are only saved there after the restart."))
        }
        .onChange(of: needsRestart) { _, showing in
            // However the alert is dismissed, restart: until then, edits would still go
            // to the old location and be missing from the new one.
            if !showing { StoreLocation.relaunch() }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = tr("Choose data storage folder")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if StoreLocation.isCloudSynced(url) {
            cloudChoice = url
        } else {
            requestMove(to: url, mirror: nil)
        }
    }

    private func requestMove(to directory: URL, mirror: URL?) {
        let move = PendingMove(directory: directory, mirror: mirror)
        if StoreLocation.hasStore(in: directory) {
            existingStoreMove = move
        } else {
            performMove(move, policy: .refuse)
        }
    }

    private func performMove(_ move: PendingMove, policy: StoreLocation.ExistingStorePolicy) {
        do {
            try modelContext.save()
            try StoreLocation.moveStore(to: move.directory, existing: policy)
            if let mirror = move.mirror { preferences.backupMirrorDirectory = mirror }
            needsRestart = true
        } catch {
            moveError = error.localizedDescription
        }
    }
}

// MARK: - Backups

private struct BackupSettings: View {
    @Environment(BackupManager.self) private var backups
    @Environment(Preferences.self) private var preferences
    @State private var pendingRestore: BackupSnapshot?
    @State private var restoreResult = StoreLocation.takeRestoreResult()

    var body: some View {
        Form {
            if let restoreResult {
                Section {
                    Label(restoreResult, systemImage: "checkmark.circle")
                }
            }

            Section {
                if let date = backups.lastBackup {
                    LabeledContent(tr("Last backup")) {
                        Text(date.formatted(.app.day().month().year().hour().minute()))
                            .foregroundStyle(.secondary)
                    }
                }
                if let error = backups.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                HStack {
                    Button(tr("Back Up Now")) {
                        Task { await backups.run(force: true) }
                    }
                    .disabled(backups.isRunning)
                    Button(tr("Show Backups")) {
                        try? FileManager.default.createDirectory(at: backups.directory, withIntermediateDirectories: true)
                        NSWorkspace.shared.open(backups.directory)
                    }
                }
            } header: {
                Text(tr("Database Backups"))
            } footer: {
                Text(tr("A verified backup is saved daily while the app is running (skipped when nothing changed). The latest 30 are kept on this Mac."))
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preferences.backupMirrorDirectory?.path ?? tr("Not set"))
                            .font(.caption)
                            .foregroundStyle(preferences.backupMirrorDirectory == nil ? .tertiary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button(tr("Choose Folder…")) { chooseMirror() }
                    if preferences.backupMirrorDirectory != nil {
                        Button(tr("Stop Copying")) { preferences.backupMirrorDirectory = nil }
                    }
                }
                if let error = backups.mirrorErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(tr("Copy Backups To"))
            } footer: {
                Text(tr("Also copy each backup to another folder — for example a cloud drive — so your data survives losing this Mac."))
            }

            Section(tr("Restore")) {
                if backups.snapshots.isEmpty {
                    Text(tr("No backups yet."))
                        .foregroundStyle(.secondary)
                }
                ForEach(backups.snapshots) { snapshot in
                    HStack {
                        Text(snapshot.date.formatted(.app.weekday(.abbreviated).day().month().year().hour().minute()))
                            .monospacedDigit()
                        Text(ByteCountFormatter.string(fromByteCount: snapshot.size, countStyle: .file))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Button(tr("Restore…")) { pendingRestore = snapshot }
                            .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { backups.refresh() }
        .confirmationDialog(tr("Restore this backup?"), isPresented: Binding(
            get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }
        ), presenting: pendingRestore) { snapshot in
            Button(tr("Restore and Restart"), role: .destructive) { backups.restore(snapshot) }
            Button(tr("Cancel"), role: .cancel) {}
        } message: { snapshot in
            Text(tr("Work Tracker restarts and replaces the current data with the backup from %@. The current database is kept in the Backups folder.",
                    snapshot.date.formatted(.app.day().month().year().hour().minute())))
        }
    }

    private func chooseMirror() {
        let panel = NSOpenPanel()
        panel.title = tr("Choose a folder for backup copies")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        preferences.backupMirrorDirectory = url
        Task { await backups.run(force: true) }
    }
}
