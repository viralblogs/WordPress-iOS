import CoreData

public protocol CoreDataStack {

    /// The read-only context, used for main thread operations to read data.
    ///
    /// This context should never be written to – use `performWriteOperation` for that.
    ///
    var viewContext: NSManagedObjectContext { get }

    /// Perform a synchronous write operation defined by the provided `operation` block, saving any changes made.
    ///
    /// Prefer using the async version of this method where possible.
    ///
    /// - Parameters:
    ///    - andWait: A block that takes an `NSManagedObjectContext` to perform write operations against
    ///
    func performWriteOperationAndWait(_ operation: @escaping (NSManagedObjectContext) throws -> Void) -> Result<Void, Error>

    /// Asyncronously perform a write operation, saving any changes made
    ///
    /// - Parameters:
    ///     - async:  A block that takes an `NSManagedObjectContext` to perform write operations against. Errors thrown from this block will cause the `onCompletion` block to provide an error `Result`.
    ///     - onCompletion:  A block called once the changes have been saved. The block provides a `Result` type containing any errors encountered during while saving, as well as any errors thrown from the `operation` block.
    ///
    /// - Returns: True if the process succeeded and didn't run into any errors. False if there was any problem and the store was left untouched.
    ///
    /// - Throws: A whole bunch of crap is possible to be thrown between Core Data and FileManager.
    ///
    func performWriteOperation(_ operation: @escaping (NSManagedObjectContext) throws -> Void, onCompletion: @escaping (Result<Void, Error>) -> Void)
}
