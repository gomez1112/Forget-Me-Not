import SwiftData
import SwiftUI

enum CelmiTab: Hashable, CaseIterable, Identifiable {
    case today
    case upcoming
    case people
    case settings

    var id: Self { self }
}

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(EntitlementService.self) private var entitlementService
    @Query(sort: \Person.fullName) private var people: [Person]

    @Bindable var settings: AppSettings

    @State private var selection: CelmiTab = .today
    @State private var showingRoutedAddDate = false
    @State private var showingRoutedPaywall = false

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
        .onAppear {
            consumePendingAppIntentRouteSoon()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            consumePendingAppIntentRouteSoon()
        }
        .sheet(isPresented: $showingRoutedAddDate) {
            AddEditPersonView(settings: settings)
        }
        .sheet(isPresented: $showingRoutedPaywall) {
            PaywallView()
        }
#if os(iOS)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(CelmiDesign.background.opacity(0.96), for: .tabBar)
#endif
    }

    private func consumePendingAppIntentRouteSoon() {
        consumePendingAppIntentRoute()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            consumePendingAppIntentRoute()
        }
    }

    private func consumePendingAppIntentRoute() {
        guard let destination = CelmiAppIntentRouteStore.consumeDestination() else { return }

        switch destination {
        case .today:
            selection = .today
        case .upcoming:
            selection = .upcoming
        case .people:
            selection = .people
        case .settings:
            selection = .settings
        case .addDate:
            selection = .people
            if entitlementService.isPro || people.count < entitlementService.freePeopleLimit {
                showingRoutedAddDate = true
            } else {
                showingRoutedPaywall = true
            }
        }
    }
}
