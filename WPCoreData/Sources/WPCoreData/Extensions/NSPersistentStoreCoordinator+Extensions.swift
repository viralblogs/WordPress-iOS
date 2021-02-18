import CoreData

extension NSPersistentStoreCoordinator {

    enum MetadataError: Error {
        case unableToDeterminePersistentStoreModelVersion

    }

    static func currentVersionForPersistentStore(ofType type: String, at url: URL) throws -> String {
        let metadata = try metadataForPersistentStore(ofType: type, at: url)

        /// The store's metdata.plist file has a key that refers to its current version – we'll inspect that and use it to find our model
        /// The store would have to be corrupt in order for this not to work, but it is *possible* (the binary `.plist` file could be invalid)
        guard
            let versionIdentifiers = metadata["NSStoreModelVersionIdentifiers"] as? [String],
            let versionName: String = versionIdentifiers.first
        else {
            throw MetadataError.unableToDeterminePersistentStoreModelVersion
        }

        return versionName
    }
}
