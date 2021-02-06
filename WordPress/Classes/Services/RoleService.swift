import Foundation
import WordPressKit

/// Service providing access to user roles
///
struct RoleService {

    fileprivate let coreDataStack: CoreDataStack
    fileprivate let remote: PeopleServiceRemote
    fileprivate let siteID: Int

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - siteID: The siteID this service will operate on
    ///     - coreDataStack: CoreDataStack to be used.
    ///     - api: A WordPress.com Rest API Instance
    ///
    init(siteID: Int, coreDataStack: CoreDataStack, api: WordPressComRestApi) {
        self.remote = PeopleServiceRemote(wordPressComRestApi: api)
        self.siteID = siteID
        self.coreDataStack = coreDataStack
    }

    /// Returns an immutable role from Core Data with the given slug.
    ///
    @inlinable
    func getRole(slug: String) -> RemoteRole? {
        getManagedRole(slug: slug)?.toUnmanaged()
    }

    /// Returns a Role (an NSManagedObject subclass) assocaited with the given `slug`
    ///
    /// Parameters:
    /// - slug: The role slug (ex: `administrator`)
    func getManagedRole(slug: String) -> Role? {
        precondition(Thread.isMainThread, "`RoleService.getManagedRole` must be called from the main thread")
        return Role.find(withSlug: slug, andSiteId: siteID, in: coreDataStack.mainContext)
    }

    /// Fetches all local roles for the given blog
    ///
    func getRoles(forSiteWithID siteID: Int) -> [RemoteRole] {
        precondition(Thread.isMainThread, "`RoleService.getRolesForSiteWithID` must be called from the main thread")
        let predicate = NSPredicate(format: "blog.blogID = %d", siteID)
        let sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return coreDataStack.mainContext.allObjects(ofType: Role.self, matching: predicate, sortedBy: sortDescriptors).map { $0.toUnmanaged() }
    }

    /// Forces a refresh of roles from the api and stores them in Core Data.
    ///
    func fetchRoles(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.getUserRoles(siteID, success: { (remoteRoles) in
            coreDataStack.performBackgroundOperationAndSave { context in
                mergeRoles(forBlogWithId: self.siteID, remoteRoles, in: context)
            } onCompletion: {
                onCompletion(.success(()))
            }
        }, failure: { error in
            onCompletion(.failure(error))
        })
    }
}

private extension RoleService {
    func mergeRoles(forBlogWithId siteID: Int, _ remoteRoles: [RemoteRole], in context: NSManagedObjectContext) {

        guard let blog = try? Blog.find(withID: siteID, in: context) else {
            return
        }

        let existingRoles = blog.roles ?? []
        var rolesToKeep = [Role]()
        for (order, remoteRole) in remoteRoles.enumerated() {
            let role: Role
            if let existingRole = existingRoles.first(where: { $0.slug == remoteRole.slug }) {
                role = existingRole
            } else {
                role = context.insertNewObject(ofType: Role.self)
            }
            role.blog = blog
            role.slug = remoteRole.slug
            role.name = remoteRole.name
            role.order = order as NSNumber
            rolesToKeep.append(role)
        }

        let rolesToDelete = existingRoles.subtracting(rolesToKeep)
        rolesToDelete.forEach(context.delete)
    }
}
