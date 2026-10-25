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

    /// The M0 spikes are reachable. In the simulator, splats explain they need a device
    /// and photogrammetry reports itself unsupported.
    @MainActor
    func testSpikesOpen() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["projects.spikes"].tap()
        app.buttons["projects.splatSpike"].tap()
        XCTAssertTrue(app.staticTexts["Device only"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["projects.spikes"].tap()
        app.buttons["projects.photogrammetrySpike"].tap()
        // LabeledContent is one accessibility element: label "Supported on this device", value "No".
        let supported = app.descendants(matching: .any).matching(identifier: "spike.supported").firstMatch
        XCTAssertTrue(supported.waitForExistence(timeout: 5))
        XCTAssertTrue([supported.label, supported.value as? String ?? ""].joined(separator: " ").contains("No"))
    }
}
