import CoreData

extension NSManagedObjectModel {

    /// Determine whether this model is compatible with the on-disk (or in-memory) store
    ///
    func isCompatibleWithStore(at storeURL: URL, configuration: String? = nil) throws -> Bool {
        // Get the persistent store's metadata.  The metadata is used to
        // get information about the store's managed object model.
        let metadata = try NSPersistentStore.metadataForPersistentStore(with: storeURL)

        return self.isConfiguration(withName: configuration, compatibleWithStoreMetadata: metadata)
    }
}
