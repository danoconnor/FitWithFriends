//
//  WelcomeScreenTests.swift
//  FitWithFriends UITests
//
//  Created by Dan O'Connor on 3/27/26.
//

import XCTest

final class WelcomeScreenTests: FWFUITestBase {
    private var signInButton: XCUIElement {
        app.buttons["signInButton"]
    }

    func testWelcomeScreenAppearance() {
        launchApp(loggedIn: false)

        // Verify welcome screen elements
        XCTAssertTrue(app.staticTexts["Fit With Friends"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Compete. Move. Win."].exists)

        // The Sign In with Apple button should be present
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3))

        takeScreenshot(name: "01_WelcomeScreen")
    }

    func testSignInButtonReplacedBySpinnerWhileLoginInProgress() {
        // Default mock outcome is `.pending` — the delegate is never called,
        // so the app stays in `.inProgress` login state after tapping sign-in.
        launchApp(loggedIn: false)

        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()

        // Spinner should appear...
        XCTAssertTrue(app.activityIndicators["loginProgressSpinner"].waitForExistence(timeout: 3))
        // ...and the sign-in button should be gone
        XCTAssertFalse(signInButton.exists)

        takeScreenshot(name: "02_LoginInProgress")
    }

    func testLoginSuccessNavigatesToHomeScreen() {
        // Mock immediately calls the delegate with a success token on sign-in tap
        launchApp(loggedIn: false, loginOutcome: "success")

        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()

        // After successful login the welcome screen is replaced by the home screen
        XCTAssertTrue(app.staticTexts["Fit with Friends"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Compete. Move. Win."].exists)

        takeScreenshot(name: "03_LoginSuccess")
    }

    func testLoginFailureShowsErrorBannerAndRestoresButton() {
        // Mock immediately calls the delegate with a failure on sign-in tap
        launchApp(loggedIn: false, loginOutcome: "failure")

        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()

        // Error banner with the failure message should appear...
        XCTAssertTrue(app.staticTexts["Login failed. Please try again"].waitForExistence(timeout: 5))
        // ...and the sign-in button should be visible again
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3))

        takeScreenshot(name: "04_LoginFailure")
    }
}
