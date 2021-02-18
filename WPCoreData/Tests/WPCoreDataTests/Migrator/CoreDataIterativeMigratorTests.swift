import XCTest
import CoreData
@testable import WPCoreData

/// Test cases for `CoreDataIterativeMigrator`.
///
/// Test cases for migrating from a model version to another should be in `MigrationTests`.
///

final class CoreDataIterativeMigratorTests: XCTestCase {

    private var modelsInventory: ManagedObjectModelsInventory!

    private let modelUrl = Bundle.module.url(
        forResource: "CoreDataIterativeMigratorTestModel",
        withExtension: "momd"
    )!

    private var model: NSManagedObjectModel {
        NSManagedObjectModel(contentsOf: modelUrl)!
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageURL: modelUrl)
    }

    override func tearDown() {
        modelsInventory = nil
        super.tearDown()
    }

    func testThatIterativeMigratorThrowsForMissingDatabaseFile() throws {
        // Given
        let databaseURL = URL(fileURLWithPath: "database-file-that-does-not-exist")

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: NSPersistentStoreCoordinator(),
            modelsInventory: modelsInventory
        )

        // Then
        XCTAssertThrowsError(
            try migrator.iterativeMigrate(
                sourceStore: databaseURL,
                storeType: NSSQLiteStoreType,
                to: model
            )
        )
    }

    func testThatIterativeMigratorReturnsSuccessForCompatibleDatabaseVersion() throws {
        // Given
        let container = try createStore(atVersion: .current)
        let databaseURL = try XCTUnwrap(container.persistentStoreDescriptions.first?.url)

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelsInventory
        )

        // Then
        XCTAssertNoThrow(
            try migrator.iterativeMigrate(
                sourceStore: databaseURL,
                storeType: NSSQLiteStoreType,
                to: model
            )
        )
    }

    func testThatIterativeMigratorThrowsForIncompatibleModel() throws {
        // Given
        let container = try createStore(atVersion: .current)
        let databaseURL = try XCTUnwrap(container.persistentStoreDescriptions.first?.url)
        let incompatibleModel = NSManagedObjectModel()

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelsInventory
        )

        // Then
        XCTAssertThrowsError(
            try migrator.iterativeMigrate(
                sourceStore: databaseURL,
                to: incompatibleModel
            )
        )
    }

    func testThatIterativeMigratorCanPerformInferredMigration() throws {
        // Given
        let container = try createStore(atVersion: .first)
        let databaseURL = try XCTUnwrap(container.persistentStoreDescriptions.first?.url)

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelsInventory
        )

        // Then
        XCTAssertNoThrow(
            try migrator.iterativeMigrate(
                sourceStore: databaseURL,
                to: managedObjectModel(for: "Model 2")
            )
        )
    }

    func testThatIterativeMigratorCanPerformMappedMigration() throws {
        // Given
        let container = try createStore(atVersion: "Model 2")
        let databaseURL = try XCTUnwrap(container.persistentStoreDescriptions.first?.url)

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelsInventory
        )

        // Then
        XCTAssertNoThrow(
            try migrator.iterativeMigrate(
                sourceStore: databaseURL,
                to: managedObjectModel(for: "Model 3")
            )
        )
    }

    func testThatIterativeMigratorDeletesIntermediateStores() throws {
        // Given
        let container = try createStore(atVersion: .first)
        let databaseURL = try XCTUnwrap(container.persistentStoreDescriptions.first?.url)

        // When
        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelsInventory
        )

        try migrator.iterativeMigrate(
            sourceStore: databaseURL,
            to: managedObjectModel(for: .current)
        )

        // Then
        let storageDirectory = databaseURL.deletingLastPathComponent().path
        let contents = try FileManager.default
            .contentsOfDirectory(atPath: storageDirectory)
        XCTAssertNil(contents.first { $0.contains("migration")})
    }
}

typealias ModelName = String
extension ModelName {
    static let first = UUID().uuidString
    static let current = UUID().uuidString
}

/// Helpers for the Core Data migration tests
private extension CoreDataIterativeMigratorTests {

    func managedObjectModel(for modelName: ModelName) throws -> NSManagedObjectModel {

        if modelName == .first {
            let version = modelsInventory.versions.first!
            return try XCTUnwrap(modelsInventory.model(for: version))
        }

        if modelName == .current {
            return modelsInventory.currentModel
        }

        let modelVersion = ManagedObjectModelsInventory.ModelVersion(name: modelName)
        return try XCTUnwrap(modelsInventory.model(for: modelVersion))
    }

    func createStore(atVersion name: ModelName) throws -> NSPersistentContainer {
        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let file = directory
            .appendingPathComponent("store")
            .appendingPathExtension("sqlite")

        let model = try managedObjectModel(for: name)
        return try startPersistentContainer(storeURL: file, storeType: NSSQLiteStoreType, model: model)
    }

    func makePersistentContainer(storeURL: URL, storeType: String, model: NSManagedObjectModel) -> NSPersistentContainer {
        let description: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = false
            description.type = storeType
            return description
        }()

        let container = NSPersistentContainer(name: "ContainerName", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        return container
    }

    /// Creates an `NSPersistentContainer` and load the store. Returns the loaded `NSPersistentContainer`.
    func startPersistentContainer(storeURL: URL, storeType: String, model: NSManagedObjectModel) throws -> NSPersistentContainer {
        let container = makePersistentContainer(storeURL: storeURL, storeType: storeType, model: model)

        let loadingError: Error? = waitFor { promise in
            container.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return container
    }
}
