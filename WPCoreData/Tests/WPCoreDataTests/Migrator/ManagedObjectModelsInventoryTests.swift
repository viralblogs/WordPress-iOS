import XCTest
import CoreData
@testable import WPCoreData

private let packageName = "ManagedObjectModelsInventoryTestModel"
private let modelUrl = Bundle.module.url(forResource: packageName, withExtension: "momd")!

/// Test cases for `CoreDataIterativeMigrator`.
///
/// Test cases for migrating from a model version to another should be in `MigrationTests`.
///
final class ManagedObjectModelsInventoryTests: XCTestCase {

    private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion
    private typealias IntrospectionError = ManagedObjectModelsInventory.IntrospectionError

    private let bundle = Bundle.module

    private var temporaryFile: URL!

    override func setUp() {
        temporaryFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        temporaryFile = nil
    }

    func testThatIterativeMigratorCanOpenModelInBundle() throws {
        let modelInventory = try ManagedObjectModelsInventory.from(packageName: packageName, bundle: Bundle.module)
        XCTAssertNotNil(modelInventory)
    }

    func testThatIterativeMigratorCanDetermineCurrentModel() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)
        XCTAssertEqual(inventory.currentModel.versionIdentifiers.first, "Model 5")
    }

    func testThatIterativeMigratorCanDetermineVersionCount() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)
        XCTAssertEqual(inventory.versions.count, 5)
    }

    func testThatIterativeMigratorCorrectlyDeterminesVersionNames() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)

        XCTAssertEqual(inventory.versions.first?.name, "Model")
        XCTAssertEqual(inventory.versions.last?.name, "Model 5")
    }

    func testThatIterativeMigratorThrowsForInvalidPackageUrl() {
        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageURL: temporaryFile)) { error in
            XCTAssertEqual(error as! IntrospectionError, IntrospectionError.failedToLoadCurrentModel)
        }
    }

    func testThatIterativeMigratorThrowsForInvalidPackageUrlInBundle() {
        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageName: "foo", bundle: bundle)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.cannotFindMomd)
        }
    }

    func testThatIterativeMigratorThrowsForInvalidManagedObjectModelUrl() throws {
        try "invalid".write(to: temporaryFile, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageURL: temporaryFile)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.failedToLoadCurrentModel)
        }
    }

    func testThatIterativeMigratorThrowsForMissingVersionInfoFile() throws {
        try createEmptyCoreDataModelWithMissingVersionInfo(at: temporaryFile)

        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageURL: temporaryFile)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.failedToLoadVersionInfoFile)
        }
    }

    func testThatIterativeMigratorThrowsForInvalidVersionInfoFile() throws {
        try createCoreDataModelWithInvalidHashes(at: temporaryFile)

        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageURL: temporaryFile)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.failedToLoadVersionHashes)
        }
    }

    func testThatModelForVersionLoadsCorrectModel() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)
        XCTAssertEqual(inventory.model(for: ModelVersion(name: "Model 2"))?.versionIdentifiers.first, "Model 2")
    }

    func testThatModelsForVersionsLoadsCorrectModels() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)
        let expectedModelNames = [
            "Model 2",
            "Model 4"
        ]

        let models = try inventory.models(for: expectedModelNames.map { ModelVersion(name: $0)})
        XCTAssertEqual(models.compactMap{ $0.versionIdentifiers.first }, expectedModelNames)
    }

    func testThatModelsForVersionThrowsForInvalidModelName() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: modelUrl)
        XCTAssertThrowsError(try inventory.models(for: [ModelVersion(name: "Foo")]))
    }

    func testThatIterativeMigratorSortsModelVersionsCorrectly() throws {
        let modelVersions = [
            "Model",
            "Model 1",
            "Model 3",
            "Model 4",
            "Model 5",
            "Model 7",
            "Model 10",
            "Model 13",
            "Model 65",
            "Model 130",
            "Model 301",
            "Model 311",
        ].map { ModelVersion(name: $0) }

        let dummyURL = try XCTUnwrap(URL(string: "https://example.com"))
        let dummyMOM = NSManagedObjectModel()
        let sortedModelVersions = ManagedObjectModelsInventory(packageURL: dummyURL,
                                                               currentModel: dummyMOM,
                                                               versions: modelVersions.shuffled()).versions

        XCTAssertEqual(sortedModelVersions, modelVersions)
    }

    //MARK: - Test Helpers
    private func createCoreDataModelWithInvalidHashes(at url: URL) throws {
        try FileManager.default.createDirectory(at: temporaryFile, withIntermediateDirectories: true)
        try NSKeyedArchiver.archivedData(withRootObject: NSManagedObjectModel(), requiringSecureCoding: true).write(to: url.appendingPathComponent(url.lastPathComponent).appendingPathExtension(".mom"))

        let infoFileUrl = url.appendingPathComponent("VersionInfo.plist")
        try NSDictionary(dictionaryLiteral: ("Key", "Value")).write(to: infoFileUrl)
    }

    private func createEmptyCoreDataModelWithMissingVersionInfo(at url: URL) throws {
        try NSKeyedArchiver.archivedData(withRootObject: NSManagedObjectModel(), requiringSecureCoding: true).write(to: url)
    }
}
