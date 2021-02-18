import XCTest

class CoreDataServiceWriteTests: XCTestCase {

    enum Errors: Error {
        case test
    }

    func testThatEmptySynchronousWriteReturnSuccessResult() throws {
        let service = try TestCoreDataService.start()
        let result = service.performWriteOperationAndWait { _ in }
        assertSuccessResult(result: result)
    }

    func testThatEmptyAsyncWriteReturnsSuccessResult() throws {
        let service = try TestCoreDataService.start()

        waitForExpectation { exp in
            service.performWriteOperation { _ in } onCompletion: { result in
                assertSuccessResult(result: result)
                exp.fulfill()
            }
        }
    }

    func testThatSynchronousWritesArePersistedSuccessfully() throws {
        let service = try TestCoreDataService.start()
        let result = service.performWriteOperationAndWait { context in
            let blog = Blog(context: context)
            blog.id = 1
            blog.title = "Test"
        }
        assertSuccessResult(result: result)
        try assertBlogExists(withID: 1, in: service.viewContext)
    }

    func testThatAsyncWritesArePersistedSuccessfully() throws {
        let service = try TestCoreDataService.start()

        waitForExpectation { exp in
            service.performWriteOperation { context in
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
        let service = try TestCoreDataService.start()
        let result = service.performWriteOperationAndWait { context in
            let blog = Blog(context: context)
            /// Blog requires an `id` set, but we're not doing that here
            blog.title = "Test"
        }
        assertFailureResult(result: result)
    }

    func testThatAsyncWriteErrorsAreEmittedOnSave() throws {
        let service = try TestCoreDataService.start()

        waitForExpectation { exp in
            service.performWriteOperation { context in
                let blog = Blog(context: context)
                /// Blog requires an `id` set, but we're not doing that here
                blog.title = "Test"
            } onCompletion: { result in
                assertFailureResult(result: result)
                exp.fulfill()
            }
        }
    }

    func testThatSynchronousOperationErrorsAreEmitted() throws {
        let service = try TestCoreDataService.start()
        let result = service.performWriteOperationAndWait { context in
            throw Errors.test
        }
        assertFailureResult(result: result)
    }

    func testThatAsyncOperationErrorsAreEmitted() throws {
        let service = try TestCoreDataService.start()

        waitForExpectation { exp in
            service.performWriteOperation { context in
                throw Errors.test
            } onCompletion: { result in
                assertFailureResult(result: result)
                exp.fulfill()
            }
        }
    }
}
