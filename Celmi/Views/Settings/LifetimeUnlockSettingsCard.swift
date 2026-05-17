import FlexStore
import StoreKit
import SwiftUI

struct LifetimeUnlockSettingsCard: View {
    @Environment(StoreKitService<CelmiAppTier>.self) private var store

    private var lifetimeProductLoaded: Bool {
        store.product(for: CelmiProductID.lifetime) != nil
    }

    private var lifetimePrice: String {
        store.product(for: CelmiProductID.lifetime)?.displayPrice ?? "$49.99"
    }

    private var isUnlocked: Bool {
        store.purchasedNonConsumables.contains(CelmiProductID.lifetime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "infinity.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CelmiDesign.gold)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Lifetime Pro")
                        .font(.headline)
                        .foregroundStyle(CelmiDesign.deepPlum)

                    Text(isUnlocked ? "Celmi Pro is unlocked forever." : "Prefer not to subscribe? Unlock Celmi Pro once and keep it forever.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            NonConsumablePurchaseButton<CelmiAppTier>(
                productID: CelmiProductID.lifetime,
                title: "Unlock Lifetime",
                purchasedTitle: "Lifetime Unlocked"
            )
            .label { state in
                LifetimeUnlockSettingsButtonLabel(
                    state: state,
                    price: lifetimePrice,
                    isProductLoaded: lifetimeProductLoaded
                )
            }
            .buttonStyle(.plain)
            .disabled(!lifetimeProductLoaded)
            .accessibilityLabel("Lifetime Celmi Pro")
            .accessibilityValue(isUnlocked ? "Unlocked" : "\(lifetimePrice), one purchase with no renewal")
        }
        .padding(.vertical, 8)
        .task {
            if !lifetimeProductLoaded {
                await store.loadProducts(CelmiProductID.all)
            }
        }
    }
}

private struct LifetimeUnlockSettingsButtonLabel: View {
    let state: FlexStoreNonConsumablePurchaseState
    let price: String
    let isProductLoaded: Bool

    var body: some View {
        HStack(spacing: 10) {
            leadingIndicator

            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)
        }
        .font(.headline)
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var leadingIndicator: some View {
        if !isProductLoaded || state == .purchasing {
            ProgressView()
                .controlSize(.small)
                .tint(foregroundStyle)
        } else {
            Image(systemName: state == .purchased ? "checkmark.circle.fill" : "sparkles")
                .accessibilityHidden(true)
        }
    }

    private var title: String {
        if !isProductLoaded {
            return "Loading Lifetime"
        }

        switch state {
        case .idle:
            return "Unlock Lifetime for \(price)"
        case .purchasing:
            return "Purchasing"
        case .purchased:
            return "Lifetime Unlocked"
        }
    }

    private var foregroundStyle: Color {
        state == .purchased ? CelmiDesign.deepPlum : .white
    }

    private var backgroundStyle: Color {
        state == .purchased ? CelmiDesign.gold.opacity(0.45) : CelmiDesign.deepPlum
    }
}
