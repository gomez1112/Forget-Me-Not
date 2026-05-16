import FlexStore
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private let features = [
        FlexPaywallFeature(systemImage: "person.2.fill", title: "Unlimited People", subtitle: "Keep every close friend and family member in Celmi.", tint: CelmiDesign.rose),
        FlexPaywallFeature(systemImage: "sparkles", title: "Custom Milestones", subtitle: "Track anniversaries, traditions, and meaningful personal dates.", tint: CelmiDesign.gold),
        FlexPaywallFeature(systemImage: "bell.badge.fill", title: "Advanced Reminders", subtitle: "Customize when and how Celmi nudges you.", tint: CelmiDesign.sage),
        FlexPaywallFeature(systemImage: "rectangle.inset.filled.and.person.filled", title: "Widgets", subtitle: "Put your next celebration on the Home Screen or Lock Screen.", tint: .indigo)
    ]

    var body: some View {
        NavigationStack {
            FlexSubscriptionPaywall<CelmiAppTier, PaywallHeader, LinearGradient, PaywallFeatureRow>(
                groupID: CelmiConstants.subscriptionGroupID,
                features: features,
                iconProvider: { tier, _ in
                    Image(systemName: tier == .pro ? "crown" : "heart")
                },
                onPurchaseCompletion: { _ in
                    dismiss()
                },
                background: {
                    CelmiDesign.heroGradient
                },
                header: {
                    PaywallHeader()
                },
                featureRow: { feature in
                    PaywallFeatureRow(feature: feature)
                }
            )
            .navigationTitle("Celmi Pro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    RestorePurchasesButton<CelmiAppTier>()
                }
                #else
                ToolbarItem(placement: .bottomBar) {
                    RestorePurchasesButton<CelmiAppTier>()
                }
                #endif
            }
        }
    }
}

struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Remember more, with less noise.")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text("Celmi Pro unlocks unlimited people, richer reminders, widgets, and private iCloud sync features.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

struct PaywallFeatureRow: View {
    let feature: FlexPaywallFeature

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.systemImage)
                .font(.title3)
                .frame(width: 34, height: 34)
                .foregroundStyle(feature.tint)
                .background(.white.opacity(0.18), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
