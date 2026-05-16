import OnboardingKit
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(CelmiModel.self) private var model
    @Bindable var settings: AppSettings

    var body: some View {
        PagedOnboardingView(
            appName: CelmiConstants.appName,
            pages: pages,
            tintColor: CelmiDesign.rose
        ) {
            settings.hasCompletedOnboarding = true
            settings.iCloudSyncEnabledExplanationShown = true
        }
    }

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: "Welcome to Celmi",
                description: "A private, beautiful place to remember the birthdays, anniversaries, and milestones of the people who matter most.",
                systemImage: "heart.text.square",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.rose
            ),
            OnboardingPage(
                title: "Import Effortlessly",
                description: "Celmi can find birthdays already saved in Contacts, so setup takes seconds. You can also add people manually.",
                systemImage: "person.crop.circle.badge.plus",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.gold,
                actionTitle: "Allow Contacts",
                action: {
                    Task { @MainActor in
                        await model.requestContactsPermission()
                    }
                },
                secondaryActionTitle: "Skip for Now",
                secondaryAction: {}
            ),
            OnboardingPage(
                title: "Gentle Reminders",
                description: "Get thoughtful reminders a week before, a day before, or the morning of a special date.",
                systemImage: "bell.badge",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.rose,
                actionTitle: "Allow Notifications",
                action: {
                    Task { @MainActor in
                        await model.requestNotificationPermission()
                    }
                },
                secondaryActionTitle: "Not Now",
                secondaryAction: {}
            ),
            OnboardingPage(
                title: "Private by Design",
                description: "Your contact data stays yours. Celmi uses on-device processing and private iCloud sync through your Apple account.",
                systemImage: "lock.icloud",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.sage
            ),
            OnboardingPage(
                title: "Be the Friend Who Remembers",
                description: "Celebrate your inner circle without social feeds, ads, or clutter.",
                systemImage: "sparkles",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.gold
            )
        ]
    }
}
