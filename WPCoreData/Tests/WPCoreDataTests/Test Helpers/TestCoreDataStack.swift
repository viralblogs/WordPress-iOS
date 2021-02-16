import Foundation
import CoreData
import WPCoreData

internal let testModelUrl = Bundle.module.url(forResource: "TestStack", withExtension: "momd")!
internal let testModel = NSManagedObjectModel(contentsOf: testModelUrl)!

class TestCoreDataService: CoreDataService {

    init() throws {
        super.init(managedObjectModel: testModel, storeDescription: NSPersistentStoreDescription())
        try super.start()
    }
}
