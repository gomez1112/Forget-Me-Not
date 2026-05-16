import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    var body: some View {
        Group {
            if let appSettings = settings.first {
                if appSettings.hasCompletedOnboarding {
                    MainTabView(settings: appSettings)
                } else {
                    OnboardingFlowView(settings: appSettings)
                }
            } else {
                ProgressView("Preparing Celmi")
                    .task {
                        modelContext.insert(AppSettings())
                        try? modelContext.save()
                    }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(CelmiDataContainer.preview)
        .environment(CelmiModel.preview)
        .environment(EntitlementService.preview)
        .environment(EntitlementService.preview.store)
}
