import XCTest

final class NurseryConnectFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testDashboardToChildDetailAddIncidentSubmit() throws {
        let emmaLink = app.buttons["dashboard.child.Emma Brown"]
        XCTAssertTrue(emmaLink.waitForExistence(timeout: 15))
        emmaLink.tap()

        let detailNav = app.navigationBars["Emma Brown"]
        XCTAssertTrue(detailNav.waitForExistence(timeout: 5))

        let addIncident = app.buttons["detail.addIncident"]
        XCTAssertTrue(addIncident.waitForExistence(timeout: 5))
        addIncident.tap()

        let incidentNav = app.navigationBars["New Incident"]
        XCTAssertTrue(incidentNav.waitForExistence(timeout: 5))

        let descriptionField = app.textViews["incident.description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        descriptionField.tap()
        descriptionField.typeText("Minor bump during UI test run.")

        app.buttons["incident.submit"].tap()

        XCTAssertTrue(detailNav.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Minor bump")).firstMatch.waitForExistence(timeout: 5))
    }
}
