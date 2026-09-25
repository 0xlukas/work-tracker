import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable, Identifiable {
    case dailyEntry = "Daily Entry"
    case projects = "Projects"
    case absences = "Absences"
    case overview = "Overview"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dailyEntry: return "calendar"
        case .projects: return "folder"
        case .absences: return "calendar.badge.minus"
        case .overview: return "chart.bar"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(Preferences.self) private var preferences
    @State private var selection: NavigationItem? = .dailyEntry
    @State private var showDailyQuote = false

    var body: some View {
        ZStack {
            NavigationSplitView {
                // The system sidebar extends to the window edge and takes on the
                // macOS 27 glass treatment on its own; keep it a plain List of Labels.
                List(NavigationItem.allCases, selection: $selection) { item in
                    Label(tr(item.rawValue), systemImage: item.icon)
                        .tag(item)
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
            } detail: {
                switch selection {
                case .dailyEntry:
                    DailyEntryView()
                case .projects:
                    ProjectsView()
                case .absences:
                    AbsencesView()
                case .overview:
                    OverviewView()
                case nil:
                    ContentUnavailableView(tr("Select an item from the sidebar"), systemImage: "sidebar.left")
                }
            }
            .frame(minWidth: 860, minHeight: 620)
            .disabled(showDailyQuote)

            if showDailyQuote {
                DailyQuoteOverlayView(quote: DailyQuote.quoteOfTheDay()) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDailyQuote = false
                    }
                    preferences.lastQuoteShownDate = Date()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Edit ▸ Undo (⌘Z) covers every change made through the shared context.
            modelContext.undoManager = undoManager
            if preferences.shouldShowDailyQuote {
                showDailyQuote = true
            }
        }
        .onChange(of: undoManager) { _, manager in
            modelContext.undoManager = manager
        }
    }
}
