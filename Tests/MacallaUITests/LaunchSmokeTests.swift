// SPDX-License-Identifier: MIT
import XCTest

/// Smoke path for the success metric (CLAUDE.md). Today it only proves the app launches;
/// each milestone extends it: capture (M1), on-device mesh (M3), budget and export (M4).
final class LaunchSmokeTests: XCTestCase {
    @MainActor
    func testLaunchShowsProjects() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Macalla"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["projects.empty"].exists || app.staticTexts["No scans yet"].exists)
    }
}
