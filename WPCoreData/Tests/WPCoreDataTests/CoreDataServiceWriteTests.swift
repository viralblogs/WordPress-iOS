import XCTest

class CoreDataServiceWriteTests: XCTestCase {

    func testThatEmptySynchronousWriteReturnSuccessResult() throws {
        let service = try TestCoreDataService()
        let result = service.performOperationAndSave { _ in }
        assertSuccessResult(result: result)
    }

    func testThatEmptyAsyncWriteReturnsSuccessResult() throws {
        let service = try TestCoreDataService()

        waitForExpectation { exp in
            service.performOperationAndSave { _ in } onCompletion: { result in
                assertSuccessResult(result: result)
                exp.fulfill()
            }
        }
    }

    func testThatSynchronousWritesArePersistedSuccessfully() throws {
        let service = try TestCoreDataService()
        let result = service.performOperationAndSave { context in
            let blog = Blog(context: context)
            blog.id = 1
            blog.title = "Test"
        }
        assertSuccessResult(result: result)
        try assertBlogExists(withID: 1, in: service.viewContext)
    }

    func testThatAsyncWritesArePersistedSuccessfully() throws {
        let service = try TestCoreDataService()

        waitForExpectation { exp in
            service.performOperationAndSave { context in
                let blog = Blog(context: context)
                blog.id = 1
                blog.title = "Test"
            } onCompletion: { result in
                assertSuccessResult(result: result)
                DispatchQueue.main.async {
                    try! self.assertBlogExists(withID: 1, in: service.viewContext)
                    exp.fulfill()
                }
            }
        }
    }

    func testThatSynchronousWriteErrorsAreEmittedOnSave() throws {
        let service = try TestCoreDataService()
        let result = service.performOperationAndSave { context in
            let blog = Blog(context: context)
            /// Blog requires an `id` set, but we're not doing that here
            blog.title = "Test"
        }
        assertFailureResult(result: result)
    }

    func testThatAsyncWriteErrorsAreEmittedOnSave() throws {
        let service = try TestCoreDataService()

        waitForExpectation { exp in
            service.performOperationAndSave { context in
                let blog = Blog(context: context)
                /// Blog requires an `id` set, but we're not doing that here
                blog.title = "Test"
            } onCompletion: { result in
                assertFailureResult(result: result)
                exp.fulfill()
            }
        }
    }
}
