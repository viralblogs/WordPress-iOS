import XCTest
import CoreData

extension XCTestCase {
    internal func assertBlogExists(withID id: Int64, in context: NSManagedObjectContext, file: StaticString = #file, line: UInt = #line) throws {
        let fetchRequest = NSFetchRequest<Blog>(entityName: "Blog")
        fetchRequest.predicate = NSPredicate(format: "id == %ld", id)
        let result = try context.fetch(fetchRequest)
        XCTAssertGreaterThanOrEqual(result.count, 1, "Number of results must be greater than or equal to one", file: file, line: line)
    }
}
