import SwiftUI
import SwiftData

@main
struct WorkTrackerApp: App {
    @State private var backups: BackupManager
    @State private var preferences = Preferences.shared
    @State private var timer = WorkTimer.shared
    private let container: ModelContainer?
    private let openError: String?

    init() {
        let storeURL = StoreLocation.storeURL
        // A restore chosen in Settings is applied here, before anything opens the store.
        StoreLocation.applyPendingRestore(to: storeURL)
        let backups = BackupManager(storeURL: storeURL)
        _backups = State(initialValue: backups)
        do {
            let container = try ModelContainer.workTracker(url: storeURL)
            if (try? VacationDay.removeDuplicates(in: container.mainContext)) ?? 0 > 0 {
                try? container.mainContext.save()
            }
            self.container = container
            self.openError = nil
            backups.start(container: container)
        } catch {
            // Never wipe or recreate the store; offer recovery instead.
            self.container = nil
            self.openError = String(describing: error)
        }
    }

    var body: some Scene {
        Window("Work Tracker", id: "main") {
            Group {
                if let container {
                    ContentView()
                        .modelContainer(container)
                } else {
                    RecoveryView(error: openError ?? "")
                }
            }
            .appEnvironment(preferences: preferences, backups: backups, timer: timer)
        }
        .defaultSize(width: 1080, height: 720)
        .windowResizability(.contentSize)
        .commands {
            // Remove the default "New Window" Cmd+N
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            Group {
                if let container {
                    SettingsView()
                        .modelContainer(container)
                } else {
                    RecoveryView(error: openError ?? "")
                }
            }
            .appEnvironment(preferences: preferences, backups: backups, timer: timer)
        }

        MenuBarExtra(isInserted: .constant(container != nil)) {
            if let container {
                MenuBarContent()
                    .modelContainer(container)
                    .appEnvironment(preferences: preferences, backups: backups, timer: timer)
            }
        } label: {
            MenuBarLabel()
                .environment(timer)
        }
        .menuBarExtraStyle(.window)
    }
}

extension View {
    /// Shared app state plus the UI language, Zurich time zone and calendar, so dates,
    /// times and pickers look the same on every screen and in every window.
    func appEnvironment(preferences: Preferences, backups: BackupManager, timer: WorkTimer) -> some View {
        var calendar = Calendar.zurich
        calendar.locale = Localization.locale
        return self
            .environment(preferences)
            .environment(backups)
            .environment(timer)
            .environment(\.locale, Localization.locale)
            .environment(\.timeZone, .zurich)
            .environment(\.calendar, calendar)
            // Re-reads on change so switching language rebuilds the UI.
            .id(preferences.language)
    }
}
