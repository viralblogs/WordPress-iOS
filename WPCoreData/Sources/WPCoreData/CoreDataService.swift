import CoreData

@objc
open class CoreDataService: NSObject, CoreDataStack {

    @objc
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public let name: String

    private let container: NSPersistentContainer

    public init(name: String = "", managedObjectModel: NSManagedObjectModel, storeDescription: NSPersistentStoreDescription) {
        container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [storeDescription]

        self.name = name
        super.init()
    }

    @discardableResult
    public func start() throws -> Self  {
        precondition(Thread.isMainThread, "The synchronous version of CoreDataService.start must be called from the main thread")
        var loadingError: Error?

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
        container.loadPersistentStores { storeDescription, error in
            guard let error = error else {
                onCompletion(.success(()))
                return
            }

            onCompletion(.failure(error))
        }
    }

    public func performOperationAndSave(synchronous operation: @escaping (NSManagedObjectContext) -> Void) -> Result<Void, Error> {

        let context = container.newBackgroundContext()

        var result: Result<Void, Error>!
        context.performAndWait {
            operation(context)
            result = save(context: context)
        }
        return result
    }

    public func performOperationAndSave(_ operation: @escaping (NSManagedObjectContext) -> Void, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        
        container.performBackgroundTask { context in
            operation(context)
            onCompletion(self.save(context: context))
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
}
