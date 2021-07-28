import XCTest

class SignupTests: XCTestCase {

    override func setUp() {
        setUpTestSuite()

        LoginFlow.logoutIfNeeded()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testEmailSignup() {
   //     let mySiteScreen = WelcomeScreen().selectSignup()
     //       .selectEmailSignup()
       //     .proceedWith(email: WPUITestCredentials.signupEmail)
         //   .openMagicSignupLink()
  //          .verifyEpilogueContains(username: WPUITestCredentials.signupUsername, displayName: WPUITestCredentials.signupDisplayName)
      //      .setPassword(WPUITestCredentials.signupPassword)
        //    .continueWithSignup()
          //  .dismissNotificationAlertIfNeeded()

        _ = PrologueScreen().selectContinue()
            .proceedWithSignup(email: WPUITestCredentials.signupEmail)
            .openMagicSignupLink()

            // this won't work, there's no way to sign up with a password.
          //  .proceedSignupWith(password: WPUITestCredentials.signupPassword)
            .verifyEpilogueContains(username: WPUITestCredentials.signupUsername, displayName: WPUITestCredentials.signupDisplayName)
            .continueWithSignup()
            .dismissNotificationAlertIfNeeded()
            .tabBar.gotoMeScreen()
            .logoutToPrologue()

        XCTAssert(PrologueScreen.isLoaded())
    }
}
