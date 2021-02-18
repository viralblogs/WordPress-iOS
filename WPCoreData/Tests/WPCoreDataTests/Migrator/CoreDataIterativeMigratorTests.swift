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


    /// Tests that model versions are not compatible with each other.
    ///
    /// This protects us from mistakes like adding a new model version that has **no structural
    /// changes** and not setting the Hash Modifier. An example of that is creating a new model
    /// but only renaming the entity classes. If we forget to change the model's Hash Modifier,
    /// then the `CoreDataManager.migrateDataModelIfNecessary` will (correctly) **skip** the
    /// migration. See here for more information: https://tinyurl.com/yxzpwp7t.
    ///
    /// This loops through **all NSManagedObjectModels**, performs a migration, and checks for
    /// compatibility with all the other versions. For example, for "Model 3":
    ///
    /// 1. Migrate the store from previous model (Model 2) to Model 3.
    /// 2. Check that Model 3 is compatible with the _migrated_ store. This verifies the migration.
    /// 3. Check that Models 1, 2, 4, 5, 6, 7, and so on are **not** compatible with the _migrated_ store.
    ///
    /// ## Testing
    ///
    /// You can make this test fail by:
    ///
    /// 1. Creating a new model version for `WooCommerce.xcdatamodeld`, copying the latest version.
    /// 2. Running this test.
    ///
    /// And then make this pass again by setting a Hash Modifier value for the new model.
    ///
    func test_all_model_versions_are_not_compatible_with_each_other() throws {

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
        let incompatibleModel = testModel

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
