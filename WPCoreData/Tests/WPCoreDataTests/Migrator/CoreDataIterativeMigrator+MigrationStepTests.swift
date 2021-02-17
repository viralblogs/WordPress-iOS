import XCTest
import CoreData
@testable import WPCoreData

private typealias MigrationStep = CoreDataIterativeMigrator.MigrationStep
private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion

/// Test cases for `MigrationStep` functions.
final class CoreDataIterativeMigrator_MigrationStepTests: XCTestCase {

    private var modelsInventory: ManagedObjectModelsInventory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageURL: testModelUrl)
    }

    override func tearDown() {
        modelsInventory = nil
        super.tearDown()
    }

}
