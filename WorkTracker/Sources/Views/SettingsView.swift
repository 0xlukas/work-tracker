import SwiftUI

struct SettingsView: View {
    @State private var currentPath: String = AppSettings.customDataDirectory?.path ?? ""
    @State private var isDefault: Bool = AppSettings.customDataDirectory == nil
    @State private var showRestartAlert = false
    @State private var migrationSucceeded = true
    @State private var dailyQuoteEnabled = AppSettings.dailyQuoteEnabled
    @State private var vacationEntitlement = AppSettings.vacationEntitlement
    @AppStorage(Localization.storageKey) private var appLanguage: AppLanguage = .system

    var body: some View {
        Form {
            Section {
                Picker(selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                } label: {
                    Text(tr("Language"))
                }
                .labelsHidden()
            } header: {
                Text(tr("Language"))
            }

            Section {
                Stepper(value: $vacationEntitlement, in: 0...60, step: 0.5) {
                    HStack {
                        Text(tr("Annual vacation entitlement"))
                        Spacer()
                        Text(tr("%@ days", TimeFormatting.days(vacationEntitlement)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .onChange(of: vacationEntitlement) { _, newValue in
                    AppSettings.vacationEntitlement = newValue
                }
            } header: {
                Text(tr("Vacation"))
            } footer: {
                Text(tr("Used for the “X / Y days” budget in Absences and Overview."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(tr("Show an inspirational quote on launch"), isOn: $dailyQuoteEnabled)
                    .onChange(of: dailyQuoteEnabled) { _, newValue in
                        AppSettings.dailyQuoteEnabled = newValue
                    }
            } header: {
                Text(tr("Daily Quote"))
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(tr("Choose where your work tracker data is stored. Use a cloud folder (e.g. Google Drive) to back up automatically. Your existing data is copied to the new location automatically."))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            if isDefault {
                                Label(tr("Default (Application Support)"), systemImage: "internaldrive")
                                    .font(.subheadline)
                                Text(defaultDirectory.path)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            } else {
                                Label(tr("Custom location"), systemImage: "folder")
                                    .font(.subheadline)
                                Text(currentPath)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }

                        Spacer()

                        Button(tr("Choose Folder...")) { chooseFolder() }

                        if !isDefault {
                            Button(tr("Reset to Default")) { resetToDefault() }
                        }
                    }
                }
            } header: {
                Text(tr("Data Storage Location"))
            }

            Section {
                DatePicker(tr("Start date"), selection: Binding(
                    get: { AppSettings.trackingStartDate },
                    set: { AppSettings.trackingStartDate = $0 }
                ), displayedComponents: .date)
            } header: {
                Text(tr("Tracking Start Date"))
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 460, idealHeight: 500)
        .alert(tr("Restart Required"), isPresented: $showRestartAlert) {
            Button(tr("OK")) {}
        } message: {
            if migrationSucceeded {
                Text(tr("Please quit and reopen the app for the new storage location to take effect. Your data was copied to the new location."))
            } else {
                Text(tr("Please quit and reopen the app for the new storage location to take effect. Your data could NOT be copied automatically — move WorkTracker.store from the old location to the new one manually before reopening."))
            }
        }
    }

    private var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WorkTracker", isDirectory: true)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = tr("Choose data storage folder")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            migrationSucceeded = AppSettings.migrateStore(to: url)
            AppSettings.customDataDirectory = url
            currentPath = url.path
            isDefault = false
            showRestartAlert = true
        }
    }

    private func resetToDefault() {
        // Copy from the current custom location back into the default folder first.
        migrationSucceeded = AppSettings.migrateStore(to: defaultDirectory)
        AppSettings.customDataDirectory = nil
        currentPath = ""
        isDefault = true
        showRestartAlert = true
    }
}
