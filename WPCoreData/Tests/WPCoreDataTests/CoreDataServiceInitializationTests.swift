import XCTest
import WPCoreData

final class CoreDataServiceInitializationTests: XCTestCase {

    /// If this test is broken, it'll just never finish
    func testThatSynchronousInitializationFinishes() throws {
        _ = try CoreDataService(managedObjectModel: testModel, storeDescription: NSPersistentStoreDescription()).start()
    }

    func testThatSynchronousInitializationFinishesForAsyncStoreDescription() throws {
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType
        storeDescription.shouldAddStoreAsynchronously = true

        let service = CoreDataService(managedObjectModel: testModel, storeDescription: storeDescription)
        try service.start()
    }

    func testThatAsyncInitializationFinishes() {
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType

        let service = CoreDataService(managedObjectModel: testModel, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: exp.fulfill()
                    case .failure(let err): XCTFail(err.localizedDescription)
                }
            }
        }
    }

    func testThatAsyncInitializationFinishesForAsyncStoreDescription() {
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType
        storeDescription.shouldAddStoreAsynchronously = true

        let service = CoreDataService(managedObjectModel: testModel, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: exp.fulfill()
                    case .failure(let err): XCTFail(err.localizedDescription)
                }
            }
        }
    }

    func testThatSynchronousInitializationEmitsFailureMessageCorrectly() {
        let storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/System/Library/Tests"))
        storeDescription.type = NSSQLiteStoreType
        let service = CoreDataService(managedObjectModel: testModel, storeDescription: storeDescription)
        XCTAssertThrowsError(try service.start())
    }

    func testThatAsyncInitializationEmitsFailureMessagesCorrectly() {
        let storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/System/Library/Tests"))
        storeDescription.type = NSSQLiteStoreType
        let service = CoreDataService(managedObjectModel: testModel, storeDescription: storeDescription)

        waitForExpectation { exp in
            service.start { result in
                switch result {
                    case .success: XCTFail("`start` should not be successful")
                    case .failure(_): exp.fulfill()
                }
            }
        }
    }
}
