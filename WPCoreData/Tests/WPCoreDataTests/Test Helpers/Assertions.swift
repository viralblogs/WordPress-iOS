import XCTest

func assertSuccessResult<T>(result: Result<T, Error>, file: StaticString = #file, line: UInt = #line) {
    switch result {
        case .success: XCTAssertTrue(true)
        case .failure(let error): XCTFail(error.localizedDescription, file: file, line: line)
    }
}

func assertFailureResult<T>(result: Result<T, Error>, file: StaticString = #file, line: UInt = #line) {
    switch result {
        case .success: XCTFail("This result should be a failure", file: file, line: line)
        case .failure(_): XCTAssertTrue(true)
    }
}
