import XCTest
import CoreData
@testable import WPCoreData

/// Test cases for `CoreDataIterativeMigrator`.
///
/// Test cases for migrating from a model version to another should be in `MigrationTests`.
///
final class CoreDataIterativeMigratorTests: XCTestCase {
    private var modelsInventory: ManagedObjectModelsInventory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageURL: testModelUrl)
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
        // todo
    }

    func test_it_will_not_migrate_if_the_database_file_does_not_exist() throws {
        // Given
        let databaseURL = URL(fileURLWithPath: "database-file-that-does-not-exist")
        let fileManager = MockFileManager()

        fileManager.whenCheckingIfFileExists(atPath: databaseURL.path, thenReturn: false)

        // Using a fake `NSPersistentStoreCoordinator` is apparently inconsequential.
        let spyCoordinator = SpyPersistentStoreCoordinator(NSPersistentStoreCoordinator())

        let migrator = CoreDataIterativeMigrator(coordinator: spyCoordinator,
                                                 modelsInventory: modelsInventory,
                                                 fileManager: fileManager)

        // When
        let result = try migrator.iterativeMigrate(sourceStore: databaseURL,
                                                   storeType: NSSQLiteStoreType,
                                                   to: testModel)

        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.debugMessages.count, 1)
        XCTAssertTrue(try XCTUnwrap(result.debugMessages.first).contains("Skipping migration."))

        XCTAssertEqual(fileManager.fileExistsInvocationCount, 1)
        XCTAssertEqual(fileManager.allMethodsInvocationCount, 1)

        XCTAssertTrue(spyCoordinator.replacements.isEmpty)
        XCTAssertTrue(spyCoordinator.destroyedURLs.isEmpty)
    }

    /// This is more like a confidence-check that Core Data does not allow us to open SQLite
    /// files using the wrong `NSManagedObjectModel`.
    func test_opening_a_store_with_a_different_model_fails() throws {
        // todo
    }

    func test_iterativeMigrate_replaces_the_original_SQLite_files() throws {
        // Given
        let storeType = NSSQLiteStoreType
        let sourceModel = try managedObjectModel(for: "Model 41")
        let targetModel = try managedObjectModel(for: "Model 42")

        let storeFileName = "Woo_Migration_Replacement_Unit_Test.sqlite"
        let storeURL = try urlForStore(withName: storeFileName, deleteIfExists: true)

        // Start a container so the SQLite files will be created.
        let container = try startPersistentContainer(storeURL: storeURL, storeType: storeType, model: sourceModel)

        // Precondition: `OrderFeeLine` should not exist in `Model 41` yet.
        assertThat(container: container, hasNoEntity: "OrderFeeLine")

        let spyCoordinator = SpyPersistentStoreCoordinator(container.persistentStoreCoordinator)

        let iterativeMigrator = CoreDataIterativeMigrator(coordinator: spyCoordinator,
                                                          modelsInventory: modelsInventory)

        // When
        let (result, _) = try iterativeMigrator.iterativeMigrate(sourceStore: storeURL,
                                                                 storeType: storeType,
                                                                 to: targetModel)
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(spyCoordinator.destroyedURLs.count, 1)
        XCTAssertEqual(spyCoordinator.replacements.count, 1)

        // The `storeURL` should have been the target of the replacement.
        let replacement = try XCTUnwrap(spyCoordinator.replacements.first)
        XCTAssertEqual(replacement.destinationURL, storeURL)
        // The sourceURL should have been from the temporary directory.
        XCTAssertEqual(replacement.sourceURL.deletingLastPathComponent(),
                       URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))

        // Assert that the same `storeURL` is using the new `Model 42`, which has the `OrderFeeLine` entity.
        let migratedContainer = try startPersistentContainer(storeURL: storeURL, storeType: storeType, model: targetModel)
        assertThat(container: migratedContainer, hasEntity: "OrderFeeLine")

    }

    func test_iterativeMigrate_will_not_migrate_if_the_database_and_the_model_are_compatible() throws {
        // todo
    }
}
