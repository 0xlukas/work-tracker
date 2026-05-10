import SwiftUI
import SwiftData

@main
struct WorkTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        let storeURL = AppSettings.dataStoreURL
        let config = ModelConfiguration(url: storeURL)
        let schema = Schema(versionedSchema: WorkTrackerSchemaV2.self)
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: WorkTrackerMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to open WorkTracker store: \(error). " +
                       "Refusing to wipe — back up your store and report this.")
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
