import XCTest

class JetpackScanScreen: BaseScreen {

    init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }
}
