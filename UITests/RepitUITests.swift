// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import XCTest

final class RepitUITests: XCTestCase {
    @MainActor func testCreditsAndBundledLegalTexts() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-uitests"]
        app.launch()
        let credits = app.buttons["creditsAndLicense"]
        XCTAssertTrue(credits.waitForExistence(timeout: 5))
        credits.tap()
        XCTAssertTrue(app.staticTexts["Copyright © 2026 gsanz.dev"].waitForExistence(timeout: 5))
        let source = app.buttons["shareSource"]
        if !source.isHittable { app.swipeUp() }
        XCTAssertTrue(source.exists, "The corresponding source archive must be bundled")
        app.buttons["readLicense"].tap()
        let license = app.staticTexts["legalText"]
        XCTAssertTrue(license.waitForExistence(timeout: 5))
        XCTAssertTrue(license.label.contains("GNU GENERAL PUBLIC LICENSE"))
        XCTAssertTrue(license.label.contains("Version 3, 29 June 2007"))
        app.buttons["BackButton"].tap()
        app.buttons["readAttribution"].tap()
        let attribution = app.staticTexts["legalText"]
        XCTAssertTrue(attribution.waitForExistence(timeout: 5))
        XCTAssertTrue(attribution.label.contains("covered repit material"))
        XCTAssertTrue(attribution.label.contains("gsanz.dev"))
        app.buttons["BackButton"].tap()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Credits and license"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["closeAbout"].tap()
    }

    @MainActor func testCreateEditPersistAndTrain() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-uitests"]
        app.launch()
        app.buttons["createRoutine"].tap()
        let name = app.textFields["routineName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("My test routine")
        app.buttons["addBlock"].tap()
        app.buttons["addExercise"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "catalogExercise.")).firstMatch.tap()
        let weight = app.textFields["exerciseWeight"]
        weight.tap()
        weight.typeText("22,5")
        app.buttons["saveExercise"].tap()
        app.buttons["addExercise"].tap()
        app.buttons["manualExercise"].tap()
        let manualName = app.textFields["exerciseName"]
        manualName.tap()
        manualName.typeText("Custom row")
        app.buttons["saveExercise"].tap()
        app.buttons["saveBlock"].tap()
        app.buttons["saveRoutine"].tap()
        XCTAssertTrue(app.staticTexts["My test routine"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Custom row"].exists)
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["My test routine"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.buttons["startWorkout"].tap()
        let firstSet = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "exerciseSet.")).firstMatch
        XCTAssertTrue(firstSet.waitForExistence(timeout: 5))
        firstSet.tap()
        XCTAssertTrue(app.staticTexts["1 / 6"].exists)
        app.buttons["exitWorkout"].tap()
        let discardActions = app.buttons.matching(identifier: "discardSession")
        discardActions.element(boundBy: discardActions.count - 1).tap()
        app.swipeDown()
        app.buttons["routineOptions"].firstMatch.tap()
        app.buttons["editRoutine"].firstMatch.tap()
        let editName = app.textFields["routineName"]
        editName.tap()
        if let text = editName.value as? String { editName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count)) }
        editName.typeText("Updated routine")
        app.buttons["saveRoutine"].tap()
        XCTAssertTrue(app.staticTexts["Updated routine"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Created and edited routine"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
