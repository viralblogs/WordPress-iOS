import XCTest
import CoreData
@testable import WPCoreData

final class CoreDataServiceInitializationTests: XCTestCase, CoreDataTestHelpers {

    /// If this test is broken, it'll just never finish
    func testThatSynchronousInitializationFinishes() throws {
        _ = try CoreDataService(modelURL: testModelUrl, storeDescription: .testDescription).start()
    }

    func testThatSynchronousInitializationFinishesForAsyncStoreDescription() throws {
        let storeDescription = NSPersistentStoreDescription.testDescription
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldAddStoreAsynchronously = true

        let service = CoreDataService(modelURL: testModelUrl, storeDescription: .testDescription)
        try service.start()
    }

    func testThatAsyncInitializationFinishes() {
        let storeDescription = NSPersistentStoreDescription.testDescription
        storeDescription.type = NSSQLiteStoreType

        let service = CoreDataService(modelURL: testModelUrl, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: break
                    case .failure(let err): XCTFail(err.localizedDescription)
                }

                exp.fulfill()
            }
        }
    }

    func testThatAsyncInitializationFinishesForAsyncStoreDescription() {
        let storeDescription = NSPersistentStoreDescription.testDescription
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldAddStoreAsynchronously = true

        let service = CoreDataService(modelURL: testModelUrl, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: break
                    case .failure(let err): XCTFail(err.localizedDescription)
                }

                exp.fulfill()
            }
        }
    }

    func testThatSynchronousInitializationEmitsFailureMessageCorrectly() {
        let storeDescription = NSPersistentStoreDescription.withInvalidUrl
        storeDescription.type = NSSQLiteStoreType
        let service = CoreDataService(modelURL: testModelUrl, storeDescription: storeDescription)
        XCTAssertThrowsError(try service.start())
    }

    func testThatAsyncInitializationEmitsFailureMessagesCorrectly() {
        let storeDescription = NSPersistentStoreDescription.withInvalidUrl
        storeDescription.type = NSSQLiteStoreType
        let service = CoreDataService(modelURL: testModelUrl, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: XCTFail("`start` should not be successful")
                    case .failure(_): break
                }

                exp.fulfill()
            }
        }
    }

    func testThatMigrationRunsForSynchronousInitialization() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: testModelUrl)
        let model = inventory.model(for: .init(name: "TestStack"))!
        let description = NSPersistentStoreDescription.testDescription

        _ = try startPersistentContainer(storeURL: description.url!, model: model)

        let modelv2 = inventory.url(for: .init(name: "TestStackv2"))
        let service = try TestCoreDataService(modelURL: modelv2, storeDescription: description)

        XCTAssertEqual(service.storeVersion, "v1")
        XCTAssertNoThrow(try service.start())
        XCTAssertEqual(service.storeVersion, "v2")
    }

    func testThatMigrationRunsForAsyncInitialization() throws {
        let inventory = try ManagedObjectModelsInventory.from(packageURL: testModelUrl)
//        _ = try createStore(withModel: inventory.model(for: .init(name: "TestStack"))!)

        let service = try TestCoreDataService(modelURL: inventory.url(for: .init(name: "TestStackv2")))
        XCTAssertEqual(service.storeVersion, "v1")

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: break
                    case .failure(let err): XCTFail(err.localizedDescription)
                }

                XCTAssertEqual(service.storeVersion, "v2")

                exp.fulfill()
            }
        }
    }
}
