import OnboardingKit
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(CelmiModel.self) private var model
    @Bindable var settings: AppSettings

    var body: some View {
        CelmiOnboardingPager(
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
                image: "CelmiInnerCircle",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.rose
            ),
            OnboardingPage(
                title: "Import Effortlessly",
                description: "Celmi can find birthdays already saved in Contacts, so setup takes seconds. You can also add people, pets, projects, and occasions manually.",
                image: "CelmiPrivateSync",
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
                image: "CelmiPrivateSync",
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
                image: "CelmiPrivateSync",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.sage
            ),
            OnboardingPage(
                title: "Be the Friend Who Remembers",
                description: "Celebrate your inner circle without social feeds, ads, or clutter.",
                image: "CelmiInnerCircle",
                backgroundColor: CelmiDesign.background,
                iconColor: CelmiDesign.gold
            )
        ]
    }
}

private struct CelmiOnboardingPager: View {
    let pages: [OnboardingPage]
    let tintColor: Color
    let onFinish: @MainActor @Sendable () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            (currentPageData?.backgroundColor ?? CelmiDesign.background)
                .ignoresSafeArea()

            if pages.isEmpty {
                emptyState
            } else {
                pageContent
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        finish()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tintColor)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.horizontal, 8)
        }
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                .background(currentPageData?.backgroundColor ?? CelmiDesign.background)
        }
#if os(iOS)
        .interactiveDismissDisabled()
#endif
    }

    @ViewBuilder
    private var pageContent: some View {
#if os(iOS)
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                onboardingPage(page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
#else
        onboardingPage(currentPageData)
#endif
    }

    private var controls: some View {
        VStack(spacing: 16) {
            indicators

            Button {
                handlePrimaryAction()
            } label: {
                Text(primaryButtonTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 520)
                    .frame(minHeight: 50)
                    .background(tintColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryButtonTitle)

            if let secondaryTitle = currentPageData?.secondaryActionButtonTitle {
                Button {
                    handleSecondaryAction()
                } label: {
                    Text(secondaryTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tintColor)
                        .frame(maxWidth: 520)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(secondaryTitle)
            }
        }
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? tintColor : Color.secondary.opacity(0.34))
                    .frame(width: currentPage == index ? 18 : 8, height: 8)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: currentPage)
                    .accessibilityHidden(true)
            }
        }
    }

    private var emptyState: some View {
        CelmiEmptyStateView(
            title: "Welcome to Celmi",
            message: "A private, beautiful place to remember the people who matter most.",
            systemImage: "heart.text.square"
        )
    }

    private var primaryButtonTitle: String {
        guard let page = currentPageData else { return "Continue" }
        if let actionButtonTitle = page.actionButtonTitle {
            return actionButtonTitle
        }
        return currentPage == pages.count - 1 ? "Start Celmi" : "Next"
    }

    private var currentPageData: OnboardingPage? {
        guard pages.indices.contains(currentPage) else { return nil }
        return pages[currentPage]
    }

    @MainActor
    private func handlePrimaryAction() {
        currentPageData?.action?()
        advanceOrFinish()
    }

    @MainActor
    private func handleSecondaryAction() {
        currentPageData?.secondaryAction?()
        advanceOrFinish()
    }

    @MainActor
    private func advanceOrFinish() {
        if currentPage < pages.count - 1 {
            if reduceMotion {
                currentPage += 1
            } else {
                withAnimation(.snappy(duration: 0.28)) {
                    currentPage += 1
                }
            }
        } else {
            finish()
        }
    }

    @MainActor
    private func finish() {
        onFinish()
    }

    @ViewBuilder
    private func onboardingPage(_ page: OnboardingPage?) -> some View {
        if let page {
            VStack(spacing: 28) {
                Spacer(minLength: 20)

                artwork(for: page)
                    .accessibilityHidden(true)

                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(CelmiDesign.deepPlum)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.78)

                    Text(page.description)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 560)
                }

                Spacer(minLength: 96)
            }
            .padding(.horizontal, 28)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func artwork(for page: OnboardingPage) -> some View {
        switch page.icon {
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(page.iconColor ?? tintColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 112, height: 112)
                .background(.white.opacity(0.62), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                }
                .shadow(color: (page.iconColor ?? tintColor).opacity(0.16), radius: 28, y: 14)
        case .asset(let image):
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .frame(height: 214)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                }
                .shadow(color: CelmiDesign.rose.opacity(0.12), radius: 28, y: 14)
        }
    }
}
