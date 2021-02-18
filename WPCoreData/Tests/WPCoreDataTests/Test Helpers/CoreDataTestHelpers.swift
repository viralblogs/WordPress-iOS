import CoreData
import XCTest

protocol CoreDataTestHelpers {
    // Intentionally left empty
}

extension CoreDataTestHelpers where Self: XCTestCase {

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
    func startPersistentContainer(storeURL: URL, storeType: String = NSSQLiteStoreType, model: NSManagedObjectModel) throws -> NSPersistentContainer {
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
