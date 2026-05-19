import FlexStore
import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private let features = [
        FlexPaywallFeature(systemImage: "person.2.fill", title: "Unlimited People", subtitle: "Keep every close friend and family member in Celmi.", tint: CelmiDesign.rose),
        FlexPaywallFeature(systemImage: "sparkles", title: "Meaningful Milestones", subtitle: "Track anniversaries, traditions, and the dates that feel personal.", tint: CelmiDesign.gold),
        FlexPaywallFeature(systemImage: "bell.badge.fill", title: "Gentler Timing", subtitle: "Choose the reminders that give you time to show up well.", tint: CelmiDesign.sage),
        FlexPaywallFeature(systemImage: "rectangle.inset.filled.and.person.filled", title: "Glanceable Widgets", subtitle: "Keep the next celebration visible on your Home Screen or Lock Screen.", tint: .indigo)
    ]

    var body: some View {
        FlexSubscriptionPaywall<CelmiAppTier, PaywallHeader, PaywallBackground, PaywallFeatureRow>(
            groupID: CelmiConstants.subscriptionGroupID,
            features: features,
            pickerItemMaterial: .regularMaterial,
            iconProvider: { tier, _ in
                Image(systemName: tier == .pro ? "crown.fill" : "heart.fill")
            },
            onPurchaseCompletion: { _ in
                dismiss()
            },
            background: {
                PaywallBackground()
            },
            header: {
                PaywallHeader()
            },
            featureRow: { feature in
                PaywallFeatureRow(feature: feature)
            }
        )
        .storeButton(.hidden, for: .restorePurchases)
        .overlay(alignment: .topTrailing) {
            PaywallCloseButton {
                dismiss()
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
        .celmiSheetSizing(width: 560, height: 720)
    }
}

private struct PaywallCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.headline.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.18), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("paywall.close")
    }
}

private struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 9) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CelmiDesign.gold)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.17), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.32), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                Text("Celmi Pro")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("A calmer way to remember every person who matters.")
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Unlimited people, richer reminders, widgets, and private iCloud sync. Still private. Still ad-free.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                PaywallTrustBadge(title: "Private", systemImage: "lock.shield")
                PaywallTrustBadge(title: "Ad-free", systemImage: "checkmark.seal")
                PaywallTrustBadge(title: "Family-ready", systemImage: "person.2")
            }
            .padding(.top, 2)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

private struct PaywallBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                CelmiDesign.deepPlum,
                Color(red: 0.43, green: 0.18, blue: 0.31),
                Color(red: 0.71, green: 0.35, blue: 0.40),
                Color(red: 0.88, green: 0.64, blue: 0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    .white.opacity(0.10),
                    .clear,
                    CelmiDesign.deepPlum.opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct PaywallTrustBadge: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

private struct PaywallFeatureRow: View {
    let feature: FlexPaywallFeature

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.systemImage)
                .font(.title3)
                .frame(width: 38, height: 38)
                .foregroundStyle(feature.tint)
                .background(.white.opacity(0.16), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
