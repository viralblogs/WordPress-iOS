import WordPressKit

extension User {

    /// Returns an immutable copy of the `User` object with the given `role`
    ///
    /// - Parameters:
    ///     - newRole: The slug associated with the user's new role
    func withRoleChangedTo(_ newRole: String) -> User {
        return User(
            ID: self.ID,
            username: self.username,
            firstName: self.firstName,
            lastName: self.lastName,
            displayName: self.displayName,
            role: newRole,
            siteID: self.siteID,
            linkedUserID: self.linkedUserID,
            avatarURL: self.avatarURL,
            isSuperAdmin: self.isSuperAdmin
        )
    }
}
