import SwiftUI

enum CelmiDesign {
    static let background = Color(red: 0.98, green: 0.95, blue: 0.91)
    static let deepPlum = Color(red: 0.18, green: 0.08, blue: 0.16)
    static let rose = Color(red: 0.82, green: 0.38, blue: 0.48)
    static let gold = Color(red: 0.86, green: 0.64, blue: 0.29)
    static let sage = Color(red: 0.42, green: 0.55, blue: 0.48)
    static let mist = Color(red: 0.93, green: 0.90, blue: 0.88)
    static let tabBarContentBottomPadding: CGFloat = 92

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.80, blue: 0.70),
                Color(red: 0.93, green: 0.68, blue: 0.78),
                Color(red: 0.98, green: 0.89, blue: 0.65)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CelmiScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background {
                CelmiDesign.background
                    .ignoresSafeArea()
            }
    }
}

struct CelmiCard: ViewModifier {
    var cornerRadius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: CelmiDesign.deepPlum.opacity(0.08), radius: 22, y: 12)
    }
}

struct CelmiTabContentClearance: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ViewBuilder
    func body(content: Content) -> some View {
#if os(iOS)
        if horizontalSizeClass == .compact {
            VStack(spacing: 0) {
                content
                Color.clear
                    .frame(height: CelmiDesign.tabBarContentBottomPadding)
                    .allowsHitTesting(false)
            }
        } else {
            content
        }
#else
        content
#endif
    }
}

extension View {
    func celmiScreenBackground() -> some View {
        modifier(CelmiScreenBackground())
    }

    func celmiCard(cornerRadius: CGFloat = 28) -> some View {
        modifier(CelmiCard(cornerRadius: cornerRadius))
    }

    func celmiTabContentClearance() -> some View {
        modifier(CelmiTabContentClearance())
    }
}

struct EventTypeBadge: View {
    let type: SpecialDateType

    var body: some View {
        Label(type.title, systemImage: type.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch type {
        case .birthday: CelmiDesign.rose
        case .anniversary: CelmiDesign.gold
        case .milestone: CelmiDesign.sage
        case .custom: .indigo
        }
    }
}

struct CelmiEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(CelmiDesign.rose)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CelmiDesign.deepPlum)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 420)
        .padding(32)
        .celmiCard()
        .accessibilityElement(children: .combine)
    }
}
