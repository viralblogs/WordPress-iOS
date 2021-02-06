import Foundation
import CocoaLumberjack
import WordPressKit

/// Service providing access to the People Management WordPress.com API.
///
struct PeopleService {
    // MARK: - Public Properties
    ///
    let siteID: Int

    // MARK: - Private Properties
    ///
    fileprivate let coreDataStack: CoreDataStack
    fileprivate let remote: PeopleServiceRemote

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - siteID: The siteID this service will operate on
    ///     - coreDataStack: CoreDataStack to be used
    ///     - api: A WordPress.com Rest API Instance
    ///
    init(siteID: Int, coreDataStack: CoreDataStack, api: WordPressComRestApi) {
        self.remote = PeopleServiceRemote(wordPressComRestApi: api)
        self.siteID = siteID
        self.coreDataStack = coreDataStack
    }

    /// Loads a page of Users associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadUsersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {
        remote.getUsers(siteID, offset: offset, count: count) { (users, hasMore) in
            self.upsertPeople(users) {
                success(users.count, hasMore)
            }
        } failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        }
    }

    /// Loads a page of Followers associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadFollowersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {
        remote.getFollowers(siteID, offset: offset, count: count) { (followers, hasMore) in
            self.upsertPeople(followers) {
                success(followers.count, hasMore)
            }
        } failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        }
    }

    /// Loads a page of Viewers associated to the current blog, starting at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: Number of records to skip.
    ///     - count: Number of records to retrieve. By default set to 20.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure.
    ///
    func loadViewersPage(_ offset: Int = 0, count: Int = 20, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void), failure: ((Error) -> Void)? = nil) {

        remote.getViewers(siteID, offset: offset, count: count) { (viewers, hasMore) in
            self.upsertPeople(viewers) {
                success(viewers.count, hasMore)
            }
        } failure: { error in
            DDLogError(String(describing: error))
            failure?(error)
        }
    }

    /// Updates a given User with the specified role.
    ///
    /// - Parameters:
    ///     - user: Instance of the person to be updated.
    ///     - newRole: New role that should be assigned
    ///     - failure: Optional closure, to be executed in case of error
    ///
    /// - Returns: A new Person instance, with the new Role already assigned.
    ///
    func updateUser(_ user: User, toRole newRole: String, failure: ((Error, User) -> Void)?) -> User {
        precondition(Thread.isMainThread, "`PeopleService.updateUser` must be called on the main thread")

        guard let managedPerson = managedPersonFromPerson(user, in: coreDataStack.mainContext) else {
            return user
        }

        // OP Reversal
        let originalRole = managedPerson.role

        // Hit the Backend
        remote.updateUserRole(siteID, userID: user.ID, newRole: newRole, success: nil, failure: { error in

            DDLogError("### Error while updating person \(user.ID) in blog \(self.siteID): \(error)")

            coreDataStack.performBackgroundOperationAndSave { context in
                guard let managedPerson = self.managedPersonFromPerson(user, in: context) else {
                    DDLogError("### Person with ID \(user.ID) deleted before update")
                    return
                }

                managedPerson.role = originalRole
            } onCompletion: {
                failure?(error, user)
            }
        })

        // Pre-emptively update the role
        coreDataStack.performBackgroundOperationAndSave { context in
            let managedPerson = self.managedPersonFromPerson(user, in: context)
            managedPerson?.role = newRole
        }

        return user.withRoleChangedTo(newRole)
    }

    /// Deletes a given User.
    ///
    /// - Parameters:
    ///     - user: The person that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteUser(_ user: User, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {

        // Hit the Backend
        remote.deleteUser(siteID, userID: user.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting person \(user.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            coreDataStack.performBackgroundOperationAndSave { (context) in
                self.createManagedPerson(user, in: context)
            } onCompletion: {
                failure?(error)
            }
        })

        // Pre-emptively nuke the entity
        coreDataStack.performBackgroundOperationAndSave { context in
            context.delete(managedPersonFromPerson(user, in: context))
        }
    }

    /// Deletes a given Follower.
    ///
    /// - Parameters:
    ///     - person: The follower that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteFollower(_ follower: Follower, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {

        // Hit the Backend
        remote.deleteFollower(siteID, userID: follower.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting follower \(follower.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            coreDataStack.performBackgroundOperationAndSave { context in
                self.createManagedPerson(follower, in: context)
            } onCompletion: {
                failure?(error)
            }
        })

        // Pre-emptively nuke the entity
        coreDataStack.performBackgroundOperationAndSave { context in
            context.delete(managedPersonFromPerson(follower, in: context))
        }
    }

    /// Deletes a given Viewer.
    ///
    /// - Parameters:
    ///     - person: The follower that should be deleted
    ///     - success: Closure to be executed in case of success.
    ///     - failure: Closure to be executed on error
    ///
    func deleteViewer(_ person: Viewer, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        guard let managedPerson = managedPersonFromPerson(person, in: coreDataStack.mainContext) else {
            return
        }

        // Hit the Backend
        remote.deleteViewer(siteID, userID: person.ID, success: {
            success?()
        }, failure: { error in
            DDLogError("### Error while deleting viewer \(person.ID) from blog \(self.siteID): \(error)")

            // Revert the deletion
            coreDataStack.performBackgroundOperationAndSave { context in
                self.createManagedPerson(person, in: context)
            }

            failure?(error)
        })

        // Pre-emptively nuke the entity
        coreDataStack.performBackgroundOperationAndSave { context in
            let managedPerson = context.object(with: managedPerson.objectID)
            context.delete(managedPerson)
        }
    }

    /// Nukes all users from Core Data.
    ///
    func removeManagedPeople() {
        coreDataStack.performBackgroundOperationAndSave { context in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
            request.predicate = NSPredicate(format: "siteID = %@", NSNumber(value: siteID))
            if let objects = (try? context.fetch(request)) as? [NSManagedObject] {
                objects.forEach { context.delete($0) }
            }
        }
    }

    /// Validates Invitation Recipients.
    ///
    /// - Parameters:
    ///     - usernameOrEmail: Recipient that should be validated.
    ///     - role: Role that would be granted to the recipient.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    func validateInvitation(_ usernameOrEmail: String,
                            role: String,
                            success: @escaping (() -> Void),
                            failure: @escaping ((Error) -> Void)) {
        remote.validateInvitation(siteID,
                                  usernameOrEmail: usernameOrEmail,
                                  role: role,
                                  success: success,
                                  failure: failure)
    }


    /// Sends an Invitation to a specified recipient, to access a Blog.
    ///
    /// - Parameters:
    ///     - usernameOrEmail: Recipient that should be validated.
    ///     - role: Role that would be granted to the recipient.
    ///     - message: String that should be sent to the users.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    func sendInvitation(_ usernameOrEmail: String,
                        role: String,
                        message: String = "",
                        success: @escaping (() -> Void),
                        failure: @escaping ((Error) -> Void)) {
        remote.sendInvitation(siteID,
                              usernameOrEmail: usernameOrEmail,
                              role: role,
                              message: message,
                              success: success,
                              failure: failure)
    }
}


/// Encapsulates all of the PeopleService Private Methods.
///
private extension PeopleService {

    /// Merge people from a network request into the core data stack
    private func upsertPeople<T: Person> (_ people: [T], onCompletion: @escaping () -> Void) {
        coreDataStack.performBackgroundOperationAndSave({ context in
            self.mergePeople(people, in: context)
        }, onCompletion: onCompletion)
    }

    /// Updates the Core Data collection of users, to match with the array of People received.
    ///
    private func mergePeople<T: Person>(_ remotePeople: [T], in context: NSManagedObjectContext) {
        for remotePerson in remotePeople {
            if let existingPerson = managedPersonFromPerson(remotePerson, in: context) {
                existingPerson.updateWith(remotePerson)
                DDLogDebug("Updated person \(existingPerson)")
            } else {
                createManagedPerson(remotePerson, in: context)
            }
        }
    }

    /// Retrieves the collection of users, persisted in Core Data, associated with the current blog.
    ///
    func loadPeople<T: Person>(_ siteID: Int, type: T.Type, in context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND kind = %@",
                                        NSNumber(value: siteID as Int),
                                        NSNumber(value: type.kind.rawValue as Int))
        let results: [ManagedPerson]
        do {
            results = try context.fetch(request) as! [ManagedPerson]
        } catch {
            DDLogError("Error fetching all people: \(error)")
            results = []
        }

        return results.map { return T(managedPerson: $0) }
    }

    /// Retrieves a Person from Core Data, with the specifiedID.
    ///
    func managedPersonFromPerson(_ person: Person, in context: NSManagedObjectContext) -> ManagedPerson? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@ AND kind = %@",
                                                NSNumber(value: siteID as Int),
                                                NSNumber(value: person.ID as Int),
                                                NSNumber(value: type(of: person).kind.rawValue as Int))
        request.fetchLimit = 1

        let results = (try? context.fetch(request) as? [ManagedPerson]) ?? []
        return results.first
    }

    /// Nukes the set of users, from Core Data, with the specified ID's.
    ///
    func removeManagedPeopleWithIDs<T: Person>(_ ids: Set<Int>, type: T.Type, in context: NSManagedObjectContext) {
        if ids.isEmpty {
            return
        }

        coreDataStack.performBackgroundOperationAndSave { context in
            let numberIDs = ids.map { return NSNumber(value: $0 as Int) }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
            request.predicate = NSPredicate(format: "siteID = %@ AND kind = %@ AND userID IN %@",
                                            NSNumber(value: siteID as Int),
                                            NSNumber(value: type.kind.rawValue as Int),
                                            numberIDs)

            let objects = (try? context.fetch(request) as? [NSManagedObject]) ?? []
            for object in objects {
                DDLogDebug("Removing person: \(object)")
                context.delete(object)
            }
        }
    }

    /// Inserts a new Person instance into Core Data, with the specified payload.
    ///
    func createManagedPerson<T: Person>(_ person: T, in context: NSManagedObjectContext) {
        let managedPerson = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context) as! ManagedPerson
        managedPerson.updateWith(person)
        managedPerson.creationDate = Date()
        DDLogDebug("Created person \(managedPerson)")
    }
}
