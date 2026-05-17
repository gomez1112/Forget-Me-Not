import FlexStore
import Foundation
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let usesPreviewProducts: Bool

    private let features = [
        FlexPaywallFeature(systemImage: "person.2.fill", title: "Unlimited People", subtitle: "Keep every close friend and family member in Celmi.", tint: CelmiDesign.rose),
        FlexPaywallFeature(systemImage: "sparkles", title: "Meaningful Milestones", subtitle: "Track anniversaries, traditions, and the dates that feel personal.", tint: CelmiDesign.gold),
        FlexPaywallFeature(systemImage: "bell.badge.fill", title: "Gentler Timing", subtitle: "Choose the reminders that give you time to show up well.", tint: CelmiDesign.sage),
        FlexPaywallFeature(systemImage: "rectangle.inset.filled.and.person.filled", title: "Glanceable Widgets", subtitle: "Keep the next celebration visible on your Home Screen or Lock Screen.", tint: .indigo)
    ]

    init(usesPreviewProducts: Bool = ProcessInfo.processInfo.arguments.contains("--preview-paywall")) {
        self.usesPreviewProducts = usesPreviewProducts
    }

    var body: some View {
        Group {
            if usesPreviewProducts {
                PaywallPreviewView(features: features)
            } else {
                storeKitPaywall
            }
        }
    }

    private var storeKitPaywall: some View {
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
        .safeAreaInset(edge: .bottom) {
            RestorePurchasesButton<CelmiAppTier>()
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
        }
        .overlay(alignment: .topTrailing) {
            PaywallCloseButton {
                dismiss()
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }
}

struct PaywallPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let features: [FlexPaywallFeature]
    @State private var selectedPlan: PaywallPreviewPlan = .yearly

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PaywallBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    PaywallHeader(isCompact: true)
                        .padding(.top, 22)

                    VStack(spacing: 10) {
                        ForEach(PaywallPreviewPlan.allCases) { plan in
                            PaywallPlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                isFeatured: plan == .yearly
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("What's Included")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))

                        VStack(spacing: 12) {
                            ForEach(features) { feature in
                                PaywallFeatureRow(feature: feature)
                            }
                        }
                    }

                    RestorePurchasesButton<CelmiAppTier>()
                        .foregroundStyle(.white)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 96)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionBar
            }

            PaywallCloseButton {
                dismiss()
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }

    private var bottomActionBar: some View {
        Button {
            dismiss()
        } label: {
            Text("Continue with \(selectedPlan.title)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(CelmiDesign.deepPlum)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue with \(selectedPlan.title) Celmi Pro")
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [
                    .clear,
                    CelmiDesign.deepPlum.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private enum PaywallPreviewPlan: String, CaseIterable, Identifiable {
    case yearly
    case monthly
    case weekly
    case lifetime

    var id: Self { self }

    var title: String {
        switch self {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .weekly: "Weekly"
        case .lifetime: "Lifetime"
        }
    }

    var subtitle: String {
        switch self {
        case .yearly: "Best for staying close all year"
        case .monthly: "Flexible Celmi Pro access"
        case .weekly: "Try Pro one week at a time"
        case .lifetime: "One purchase, no renewal"
        }
    }

    var price: String {
        switch self {
        case .yearly: "$24.99"
        case .monthly: "$2.99"
        case .weekly: "$0.99"
        case .lifetime: "$49.99"
        }
    }

    var cadence: String {
        switch self {
        case .yearly: "per year"
        case .monthly: "per month"
        case .weekly: "per week"
        case .lifetime: "once"
        }
    }
}

private struct PaywallPlanCard: View {
    let plan: PaywallPreviewPlan
    let isSelected: Bool
    let isFeatured: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.seal.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? CelmiDesign.gold : .white.opacity(0.54))
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        if isFeatured {
                            Text("Best Value")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CelmiDesign.deepPlum)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(CelmiDesign.gold, in: Capsule())
                        }
                    }

                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(plan.cadence)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(.white.opacity(isSelected ? 0.18 : 0.11), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? CelmiDesign.gold.opacity(0.76) : .white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.title), \(plan.price) \(plan.cadence)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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

struct PaywallHeader: View {
    let isCompact: Bool

    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }

    var body: some View {
        VStack(spacing: isCompact ? 14 : 18) {
            VStack(spacing: isCompact ? 9 : 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: isCompact ? 24 : 34, weight: .semibold))
                    .foregroundStyle(CelmiDesign.gold)
                    .frame(width: isCompact ? 54 : 76, height: isCompact ? 54 : 76)
                    .background(.white.opacity(0.17), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.32), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                Text("Celmi Pro")
                    .font((isCompact ? Font.title : Font.largeTitle).weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("A calmer way to remember every person who matters.")
                    .font((isCompact ? Font.headline : Font.title3).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))

                Text(isCompact ? "Unlimited people, richer reminders, widgets, and private iCloud sync. Still private. Still ad-free." : "Unlimited people, richer reminders, widgets, private iCloud sync features, and more visual themes. Still private. Still ad-free.")
                    .font(isCompact ? .footnote : .body)
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

struct PaywallBackground: View {
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

struct PaywallTrustBadge: View {
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

struct PaywallFeatureRow: View {
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
