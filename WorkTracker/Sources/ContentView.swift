import SwiftUI

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
    @State private var selection: NavigationItem? = .dailyEntry
    @State private var showDailyQuote = false
    // Re-reads on change so switching language in Settings rebuilds the UI (via .id).
    @AppStorage(Localization.storageKey) private var appLanguage: AppLanguage = .system

    var body: some View {
        ZStack {
            NavigationSplitView {
                List(NavigationItem.allCases, selection: $selection) { item in
                    Label(tr(item.rawValue), systemImage: item.icon)
                        .tag(item)
                }
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
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
                    Text(tr("Select an item from the sidebar"))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 800, minHeight: 600)
            .id(appLanguage)

            if showDailyQuote {
                DailyQuoteOverlayView(quote: DailyQuote.quoteOfTheDay()) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDailyQuote = false
                    }
                    AppSettings.lastQuoteShownDate = Date()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if AppSettings.shouldShowDailyQuote {
                showDailyQuote = true
            }
        }
    }
}
