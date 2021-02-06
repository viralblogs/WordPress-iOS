import Foundation
import CoreData

public class Role: NSManagedObject {
    @NSManaged public var name: String!
    @NSManaged public var slug: String!
    @NSManaged public var blog: Blog!
    @NSManaged public var order: NSNumber!
}

extension Role {
    func toUnmanaged() -> RemoteRole {
        return RemoteRole(slug: slug, name: name)
    }

    /// Find a role with the given `slug` and `siteID` in the given `context`
    ///
    /// - Parameters:
    ///     - slug: The `slug` for the given role (such as "administrator")
    ///     - siteID: The `blogID` for the given WordPress.com Blog
    ///     - context: The `NSManagedObjectContext` in which to find the `Role`
    /// - Throws: Internal Core Data errors associated with fetching results
    /// - Returns: The Role object from the provided `context`, if it exists
    static func find(withSlug slug: String, andSiteId siteID: Int, in context: NSManagedObjectContext) -> Role? {
        let predicate = NSPredicate(format: "slug = %@ AND blog.blogID = %d", slug, siteID)
        return context.firstObject(ofType: Role.self, matching: predicate)
    }
}

extension Role {
    @objc var color: UIColor {
        switch slug {
        case .some("super-admin"):
            return WPStyleGuide.People.superAdminColor
        case .some("administrator"):
            return WPStyleGuide.People.adminColor
        case .some("editor"):
            return WPStyleGuide.People.editorColor
        default:
            return WPStyleGuide.People.otherRoleColor
        }
    }
}
