import Foundation
import CoreData
@testable import WPCoreData

internal let testModelUrl = Bundle.module.url(forResource: "TestStack", withExtension: "momd")!

class TestCoreDataService: CoreDataService {

    private init() throws {
        super.init(modelURL: testModelUrl, storeDescription: .testDescription)
    }

    init(modelURL: URL, storeDescription: NSPersistentStoreDescription = .testDescription) throws {
        super.init(modelURL: modelURL, storeDescription: storeDescription)
    }

    static func start() throws -> TestCoreDataService {
        return try TestCoreDataService().start()
    }

    var storeDescription: NSPersistentStoreDescription {
        container.persistentStoreDescriptions.first!
    }

    var storeVersion: String {
        try! NSPersistentStoreCoordinator.currentVersionForPersistentStore(ofType: storeDescription.type, at: storeDescription.url!)
    }
}

extension NSPersistentStoreDescription {
    static var testDescription: NSPersistentStoreDescription {
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: testURL, withIntermediateDirectories: true)

        return NSPersistentStoreDescription(url: testURL.appendingPathComponent("data.sqlite"))
    }

    static var withInvalidUrl: NSPersistentStoreDescription {
        NSPersistentStoreDescription(url: URL(fileURLWithPath: "/" + UUID().uuidString))
    }
}
