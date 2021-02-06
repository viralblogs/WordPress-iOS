import CoreData

extension Blog {
    /// Lookup a Blog object in the given context by the provided `id`
    ///
    /// - Parameters:
    ///     - id: The WordPress.com Blog ID of the blog we wish to find
    ///     - context: The `NSManagedObjectContext` containing the blog
    /// - Throws: Internal Core Data errors associated with fetching results
    /// - Returns: The Blog object from the provided `context`, if it exists
    static func find(withID id: Int, in context: NSManagedObjectContext) throws -> Blog? {
        let fetchRequest = NSFetchRequest<Blog>(entityName: Blog.entityName())
        fetchRequest.predicate = NSPredicate(format: "blogID = %d", id)
        return try context.fetch(fetchRequest).first
    }
}
