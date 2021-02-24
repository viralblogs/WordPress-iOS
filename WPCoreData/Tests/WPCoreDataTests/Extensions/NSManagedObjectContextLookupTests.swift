import XCTest
import CoreData
@testable import WPCoreData

class NSManagedObjecContextLookupTests: XCTestCase {

    func testThatLookupByObjectIDReturnsExistingObject() throws {
        let service = try TestCoreDataService.start()
        let objectID = try createTestObjectID(in: service.viewContext)
        XCTAssertNotNil(Blog.lookup(withObjectID: objectID, in: service.viewContext))
    }

    func testThatLookupByObjectIDReturnsNilForMissingObject() throws {
        let service = try TestCoreDataService.start()
        let objectID = try createTestObjectID(in: service.viewContext)

        // Delete the object so the objectID is no longer valid
        try deleteTestObject(withID: objectID, in: service.viewContext)

        XCTAssertNil(Blog.lookup(withObjectID: objectID, in: service.viewContext))
    }

    private func createTestObjectID(in context: NSManagedObjectContext) throws -> NSManagedObjectID {
        let blog = Blog(context: context)
        blog.id = 1
        blog.title = "Blog"
        try context.save()

        return blog.objectID
    }

    private func deleteTestObject(withID objectID: NSManagedObjectID, in context: NSManagedObjectContext) throws {
        let object = NSManagedObject.lookup(withObjectID: objectID, in: context)!
        context.delete(object)
        try context.save()
    }
}
