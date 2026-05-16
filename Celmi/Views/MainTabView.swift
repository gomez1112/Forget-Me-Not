import SwiftUI

struct MainTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                NavigationStack {
                    DashboardView(settings: settings)
                }
            }

            Tab("Upcoming", systemImage: "calendar.badge.clock") {
                NavigationStack {
                    UpcomingEventsView()
                }
            }

            Tab("People", systemImage: "person.2") {
                NavigationStack {
                    PeopleView(settings: settings)
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView(settings: settings)
                }
            }
        }
        .tint(CelmiDesign.rose)
    }
}
