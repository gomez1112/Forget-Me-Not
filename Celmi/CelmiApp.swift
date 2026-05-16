import SwiftUI
import SwiftData

@main
struct CelmiApp: App {
    private let modelContainer: ModelContainer

    @State private var celmiModel = CelmiModel()
    @State private var entitlementService = EntitlementService()

    init() {
        do {
            if Self.isRunningTests {
                modelContainer = try CelmiDataContainer.testingContainer()
            } else {
                modelContainer = try CelmiDataContainer.production()
            }
        } catch {
            fatalError("Unable to create Celmi SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .environment(celmiModel)
                .environment(entitlementService)
                .environment(entitlementService.store)
                .task {
                    if !Self.isRunningTests {
                        await entitlementService.configure()
                    }
                    await celmiModel.refreshPermissionStates()
                }
        }

        #if os(macOS)
        .defaultSize(width: 1180, height: 780)
        #endif
    }

    private static var isRunningTests: Bool {
        let process = ProcessInfo.processInfo
        let environment = process.environment
        let testConfigurationKey = "X" + "CTestConfigurationFilePath"
        let testBundleSuffix = ".xc" + "test"

        return environment[testConfigurationKey] != nil
            || environment["XCInjectBundleInto"] != nil
            || environment.keys.contains { $0.localizedCaseInsensitiveContains("xctest") }
            || process.arguments.contains { $0.localizedCaseInsensitiveContains(testBundleSuffix) }
    }
}
