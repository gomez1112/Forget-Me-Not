import FlexStore
import Foundation

enum CelmiAppTier: String, CaseIterable, Identifiable, SubscriptionTier {
    case free
    case pro

    static var defaultTier: CelmiAppTier { .free }

    var id: String { rawValue }

    init?(levelOfService: Int) {
        self = levelOfService > 0 ? .pro : .free
    }

    init?(productID: String) {
        switch productID {
        case CelmiProductID.monthly, CelmiProductID.yearly, CelmiProductID.lifetime:
            self = .pro
        default:
            self = .free
        }
    }
}

@MainActor
@Observable
final class EntitlementService {
    let store: StoreKitService<CelmiAppTier>

    init(store: StoreKitService<CelmiAppTier> = StoreKitService<CelmiAppTier>()) {
        self.store = store
    }

    static var preview: EntitlementService {
        EntitlementService()
    }

    var tier: AppTier {
        store.subscriptionTier == .pro ? .pro : .free
    }

    var isPro: Bool {
        tier == .pro
    }

    var freePeopleLimit: Int {
        8
    }

    func configure() async {
        await store.configure(
            productIDs: CelmiProductID.all,
            subscriptionGroupID: CelmiConstants.subscriptionGroupID
        )
    }
}
