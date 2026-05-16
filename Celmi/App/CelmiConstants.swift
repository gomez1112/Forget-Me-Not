import Foundation

enum CelmiConstants {
    static let appName = "Celmi"
    static let bundleIdentifier = "com.transfinite.Celmi"
    static let cloudKitContainerIdentifier = "iCloud.com.transfinite.Celmi"
    static let appGroupIdentifier = "group.com.transfinite.Celmi"
    static let subscriptionGroupID = "com.celmi.pro"
}

enum CelmiProductID {
    static let monthly = "com.celmi.pro.monthly"
    static let yearly = "com.celmi.pro.yearly"
    static let lifetime = "com.celmi.pro.lifetime"

    static let all: Set<String> = [monthly, yearly, lifetime]
}
