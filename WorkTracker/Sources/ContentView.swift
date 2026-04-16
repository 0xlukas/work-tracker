import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dailyEntry = "Daily Entry"
    case projects = "Projects"
    case vacation = "Vacation"
    case overview = "Overview"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dailyEntry: return "calendar"
        case .projects: return "folder"
        case .vacation: return "airplane"
        case .overview: return "chart.bar"
        }
    }
}

struct ContentView: View {
    @State private var selection: NavigationItem? = .dailyEntry
    @State private var showDailyQuote = false

    var body: some View {
        ZStack {
            NavigationSplitView {
                List(NavigationItem.allCases, selection: $selection) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
            } detail: {
                switch selection {
                case .dailyEntry:
                    DailyEntryView()
                case .projects:
                    ProjectsView()
                case .vacation:
                    VacationView()
                case .overview:
                    OverviewView()
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 800, minHeight: 600)

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
