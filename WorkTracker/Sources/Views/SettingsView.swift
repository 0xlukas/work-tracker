import SwiftUI

struct SettingsView: View {
    @State private var currentPath: String = AppSettings.customDataDirectory?.path ?? ""
    @State private var isDefault: Bool = AppSettings.customDataDirectory == nil
    @State private var showRestartAlert = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Storage Location")
                        .font(.headline)

                    Text("Choose where your work tracker data is stored. Use a cloud folder (e.g. Google Drive) to back up automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            if isDefault {
                                Label("Default (Application Support)", systemImage: "internaldrive")
                                    .font(.subheadline)
                                Text(defaultPath)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            } else {
                                Label("Custom location", systemImage: "folder")
                                    .font(.subheadline)
                                Text(currentPath)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }

                        Spacer()

                        Button("Choose Folder...") {
                            chooseFolder()
                        }

                        if !isDefault {
                            Button("Reset to Default") {
                                AppSettings.customDataDirectory = nil
                                currentPath = ""
                                isDefault = true
                                showRestartAlert = true
                            }
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracking Start Date")
                        .font(.headline)

                    DatePicker("Start date", selection: Binding(
                        get: { AppSettings.trackingStartDate },
                        set: { AppSettings.trackingStartDate = $0 }
                    ), displayedComponents: .date)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 300)
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK") {}
        } message: {
            Text("Please quit and reopen the app for the new storage location to take effect. Your existing data will remain in the old location — move the files manually if needed.")
        }
    }

    private var defaultPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("WorkTracker").path
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose data storage folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            AppSettings.customDataDirectory = url
            currentPath = url.path
            isDefault = false
            showRestartAlert = true
        }
    }
}
