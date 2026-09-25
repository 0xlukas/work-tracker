import SwiftUI
import AppKit

/// Shown instead of the app when the database can't be opened. Nothing is deleted or
/// recreated; the user can restore a backup, inspect the files, or quit.
struct RecoveryView: View {
    @Environment(BackupManager.self) private var backups
    let error: String
    @State private var confirmRestore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(tr("Work Tracker can’t open its database"), systemImage: "exclamationmark.triangle.fill")
                .font(.title2.bold())
                .foregroundStyle(.orange)

            Text(tr("Your data has not been changed. You can restore the latest backup (the current file is kept), or quit and investigate the files first."))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(error)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            .padding(8)
            .cardSurface()

            if let latest = backups.snapshots.first {
                Text(tr("Latest backup: %@", latest.date.formatted(.app.day().month().year().hour().minute())))
                    .font(.callout)
            } else {
                Text(tr("No backups yet."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(tr("Restore Latest Backup…")) { confirmRestore = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(backups.snapshots.isEmpty)
                Button(tr("Show Database in Finder")) {
                    NSWorkspace.shared.activateFileViewerSelecting([backups.storeURL])
                }
                Button(tr("Show Backups")) { NSWorkspace.shared.open(backups.directory) }
                Spacer()
                Button(tr("Quit")) { NSApp.terminate(nil) }
            }
        }
        .padding(28)
        .frame(minWidth: 620, minHeight: 380)
        .confirmationDialog(tr("Restore the latest backup?"), isPresented: $confirmRestore) {
            Button(tr("Restore and Restart"), role: .destructive) {
                if let latest = backups.snapshots.first { backups.restore(latest) }
            }
            Button(tr("Cancel"), role: .cancel) {}
        } message: {
            Text(tr("The current database is moved into the Backups folder, not deleted."))
        }
    }
}
