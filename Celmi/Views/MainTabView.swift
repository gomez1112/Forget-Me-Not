import SwiftUI

enum CelmiTab: Hashable, CaseIterable, Identifiable {
    case today
    case upcoming
    case people
    case settings

    var id: Self { self }
}

struct MainTabView: View {
    @Bindable var settings: AppSettings
    @State private var selection: CelmiTab = .today

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max", value: CelmiTab.today) {
                NavigationStack {
                    DashboardView(settings: settings)
                }
            }
            .customizationID("celmi.tab.today")

            Tab("Upcoming", systemImage: "calendar.badge.clock", value: CelmiTab.upcoming) {
                NavigationStack {
                    UpcomingEventsView(settings: settings)
                }
            }
            .customizationID("celmi.tab.upcoming")

            Tab("People", systemImage: "person.2", value: CelmiTab.people) {
                NavigationStack {
                    PeopleView(settings: settings)
                }
            }
            .customizationID("celmi.tab.people")

            Tab("Settings", systemImage: "gearshape", value: CelmiTab.settings) {
                NavigationStack {
                    SettingsView(settings: settings)
                }
            }
            .customizationID("celmi.tab.settings")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(CelmiDesign.rose)
#if os(iOS)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(CelmiDesign.background.opacity(0.96), for: .tabBar)
#endif
    }
}
