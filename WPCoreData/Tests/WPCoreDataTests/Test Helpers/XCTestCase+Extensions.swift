import XCTest

extension XCTestCase {

    /// Wait the specificed time for an expectation to be fulfilled. Takes a block that receives the expecatation, so this is useful for testing async code.
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and returns a value that will become the return value of this method.
    ///     - expectation: An unfulfilled XCTestExpectation.
    func waitForExpectation(timeout: TimeInterval = 1.0, block: (_ expectation: XCTestExpectation) -> ()) {
        let exp = XCTestExpectation()
        block(exp)
        wait(for: [exp], timeout: timeout)
    }

    /// Wait the specified time for an expectation to be fulfilled. Takes a block that receives the expectation and returns a specified type
    /// so this is useful for testing async code when you need to examine a result following the expectation being met.
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and returns a value that will become the return value of this method.
    ///     - expectation: An unfulfilled XCTestExpectation.
    /// - Returns: The value provided by `block`, which can specify its own return type
    func waitForExpectation<T>(timeout: TimeInterval = 1.0, block: (_ expectation: XCTestExpectation) -> (T)) -> T {
        let exp = XCTestExpectation()
        let result = block(exp)
        wait(for: [exp], timeout: timeout)

        return result
    }

    /// Wait the specificed time for an expectation to be fulfilled. Takes a block that can throw, so this is useful for testing async code
    /// that might also `throw`.
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and performs a throwing operation.
    ///     - expectation: An unfulfilled XCTestExpectation.
    func waitForExpectation(timeout: TimeInterval = 1.0, block: (_ expectation: XCTestExpectation) throws -> ()) rethrows {
        let exp = XCTestExpectation()
        try block(exp)
        wait(for: [exp], timeout: timeout)
    }

    /// Waits until a value is provided by a promise (block) and returns that value.
    ///
    /// ## Example Usage
    ///
    /// ```
    /// let value: String = waitFor { promise in
    ///     fetchFromAPI { responseString in
    ///         promise(responseString)
    ///     }
    /// }
    ///
    /// XCTAssertEquals("expected_value", value)
    /// ```
    ///
    func waitFor<ValueType>(file: StaticString = #file,
                                   line: UInt = #line,
                                   timeout: TimeInterval = 5.0,
                                   await: @escaping (_ promise: (@escaping (ValueType) -> Void)) throws -> Void) rethrows -> ValueType {
        let exp = expectation(description: "Expect promise to be called.")

        var receivedValue: ValueType? = nil
        let promise: (ValueType) -> Void = { value in
            receivedValue = value
            exp.fulfill()
        }

        try await(promise)

        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        switch result {
        case .timedOut:
            XCTFail("Timed out waiting for done callback to be called.", file: file, line: line)
        default:
            break
        }

        return receivedValue!
    }
}
