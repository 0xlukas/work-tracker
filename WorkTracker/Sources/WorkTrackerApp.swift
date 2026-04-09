import SwiftUI
import SwiftData

@main
struct WorkTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        let storeURL = AppSettings.dataStoreURL
        let config = ModelConfiguration(url: storeURL)
        do {
            modelContainer = try ModelContainer(for: Project.self, WorkSegment.self, VacationDay.self,
                                                configurations: config)
        } catch {
            // Schema migration failed — delete old store and retry
            print("ModelContainer failed: \(error). Deleting old store and retrying.")
            let fm = FileManager.default
            let basePath = storeURL.path
            for suffix in ["", "-wal", "-shm"] {
                try? fm.removeItem(atPath: basePath + suffix)
            }
            do {
                modelContainer = try ModelContainer(for: Project.self, WorkSegment.self, VacationDay.self,
                                                    configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        Window("Work Tracker", id: "main") {
            ContentView()
        }
        .modelContainer(modelContainer)
        .windowResizability(.contentSize)
        .commands {
            // Remove the default "New Window" Cmd+N
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}
