import CoreData

@objc
open class CoreDataService: NSObject, CoreDataStack {

    public enum CoreDataServiceError: Error {
        case unableToReadModel
        case storeUrlIsNotWriteable
    }

    @objc
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public let name: String

    internal let container: NSPersistentContainer

    private let modelURL: URL
    private let storeURL: URL

    private let storeType: String

    public init(
        name: String = Bundle.main.bundleIdentifier ?? "CoreData",
        modelURL: URL,
        storeDescription: NSPersistentStoreDescription
    ) {
        precondition(FileManager.default.fileExists(atPath: modelURL.path), "There is no model at \(modelURL)")

        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        precondition(managedObjectModel != nil, "Unable to read model from \(modelURL)")

        container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel!)
        container.persistentStoreDescriptions = [storeDescription]

        self.name = name
        self.modelURL = modelURL
        self.storeType = storeDescription.type
        self.storeURL = storeDescription.url!

        super.init()
    }

    @discardableResult
    public func start() throws -> Self  {
        precondition(Thread.isMainThread, "The synchronous version of CoreDataService.start must be called from the main thread")
        var loadingError: Error?

        try migrateDataModelIfNeeded()

        let sema = DispatchSemaphore(value: 0)

        /// We need a dispatch queue here because `loadPersistentStores` calls its block on the main thread, which is blocked
        /// by the semaphore waiting for the load to complete, causing a deadlock. We break this by caling `loadPersistentStores`
        /// inside a different queue (thus not on the main therad), which causes the completion block to run outside the main thread as well.
        DispatchQueue(label: "core-data-service-initializer").async {
            self.container.loadPersistentStores { storeDescription, error in
                loadingError = error
                sema.signal()
            }
        }
        sema.wait()

        if let error = loadingError {
            throw error
        }
        
        return self
    }

    public func start(onCompletion: @escaping (Result<Void, Error>) -> Void) {

        do {
            try migrateDataModelIfNeeded()
        } catch let error {
            onCompletion(.failure(error))
            return
        }

        container.loadPersistentStores { storeDescription, error in
            guard let error = error else {
                onCompletion(.success(()))
                return
            }

            onCompletion(.failure(error))
        }
    }

    public func performWriteOperationAndWait(_ operation: @escaping (NSManagedObjectContext) throws -> Void) -> Result<Void, Error> {

        precondition(container.persistentStoreCoordinator.persistentStores.count > 0, "You must call `start` on CoreDataService` before performing queries")
        let context = container.newBackgroundContext()

        var result: Result<Void, Error>!
        context.performAndWait {
            do {
                try operation(context)
                result = save(context: context)
            } catch let error {
                result = .failure(error)
            }
        }
        return result
    }

    public func performWriteOperation(_ operation: @escaping (NSManagedObjectContext) throws -> Void, onCompletion: @escaping (Result<Void, Error>) -> Void) {

        precondition(container.persistentStoreCoordinator.persistentStores.count > 0, "You must call `start` on CoreDataService` before performing queries")

        container.performBackgroundTask { context in
            do {
                try operation(context)
                onCompletion(self.save(context: context))
            } catch let error {
                onCompletion(.failure(error))
            }
        }
    }

    private func save(context: NSManagedObjectContext) -> Result<Void, Error> {
        guard context.hasChanges else {
            return .success(())
        }

        do {
            try context.save()
            return .success(())
        } catch let error {
            return .failure(error)
        }
    }

    private func migrateDataModelIfNeeded() throws {
        /// If the model is in-memory or hasn't been created yet there's no work for us to do
        guard
            storeType != NSInMemoryStoreType,
            FileManager.default.fileExists(atPath: storeURL.path)
        else {
            return
        }

        let modelInventory = try ManagedObjectModelsInventory.from(packageURL: modelURL)

        let migrator = CoreDataIterativeMigrator(
            coordinator: container.persistentStoreCoordinator,
            modelsInventory: modelInventory
        )

        try migrator.iterativeMigrate(
            sourceStore: storeURL,
            storeType: storeType,
            to: modelInventory.currentModel
        )
    }
}
