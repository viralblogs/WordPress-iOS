import CoreData

public protocol CoreDataStack {
    var viewContext: NSManagedObjectContext { get }

    func performOperationAndSave(synchronous operation: @escaping (NSManagedObjectContext) -> Void) -> Result<Void, Error>
    func performOperationAndSave(_ operation: @escaping (NSManagedObjectContext) -> Void, onCompletion: @escaping (Result<Void, Error>) -> Void)
}
