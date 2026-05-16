import EZSwiftData
import Foundation
import SwiftData

enum CelmiDataContainer {
    static let modelTypes: [any PersistentModel.Type] = [
        Person.self,
        SpecialDate.self,
        ReminderPreference.self,
        AppSettings.self
    ]

    @MainActor
    static func production() throws -> ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(CelmiConstants.cloudKitContainerIdentifier)
        )

        return try ModelContainer(for: schema, configurations: configuration)
    }

    @MainActor
    static var preview: ModelContainer {
        do {
            return try previewContainer()
        } catch {
            fatalError("Unable to create Celmi preview container: \(error)")
        }
    }

    @MainActor
    static func previewContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSeeded(
            for: modelTypes,
            isStoredInMemoryOnly: true
        ) { context in
            try CelmiSampleData.seed(into: context, hasCompletedOnboarding: true)
        }
    }

    @MainActor
    static func testingContainer() throws -> ModelContainer {
        try ModelContainerFactory.create(
            for: modelTypes,
            isStoredInMemoryOnly: true
        )
    }
}
