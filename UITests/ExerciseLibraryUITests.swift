// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import XCTest

final class ExerciseLibraryUITests: XCTestCase {
    @MainActor func testCustomTimedExercisePersistsAndCanBeReused() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-uitests"]
        app.launch()
        app.buttons["createRoutine"].tap()
        app.textFields["routineName"].tap()
        app.textFields["routineName"].typeText("Timed routine")
        app.buttons["addBlock"].tap()
        app.buttons["addExercise"].tap()
        app.buttons["manualExercise"].tap()
        app.textFields["exerciseName"].tap()
        app.textFields["exerciseName"].typeText("Wall sit custom")
        let muscle = app.textFields["exerciseMuscle"]
        muscle.tap()
        if let value = muscle.value as? String { muscle.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)) }
        muscle.typeText("  lEgS  ")
        app.segmentedControls["exerciseMeasurement"].buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.steppers["exerciseDuration"].exists)
        XCTAssertFalse(app.steppers["exerciseRepetitions"].exists)
        app.steppers["exerciseDuration"].buttons.element(boundBy: 1).tap()
        app.buttons["saveExercise"].tap()
        app.buttons["saveBlock"].tap()
        app.buttons["saveRoutine"].tap()
        XCTAssertTrue(app.staticTexts["Timed routine"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Wall sit custom", "35 s")).firstMatch.exists)
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.tabBars.buttons.element(boundBy: 1).tap()
        app.buttons["muscleFilter.legs"].tap()
        let saved = app.buttons["libraryExercise.Wall sit custom"]
        if !saved.isHittable { app.swipeUp() }
        XCTAssertTrue(saved.exists, "Custom exercises must survive relaunch and appear in their matched muscle category")

        app.tabBars.buttons.element(boundBy: 0).tap()
        app.buttons["createRoutine"].tap()
        app.buttons["addBlock"].tap()
        app.buttons["addExercise"].tap()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Wall sit custom")
        app.buttons["catalogExercise.Wall sit custom"].tap()
        XCTAssertTrue(app.steppers["exerciseDuration"].label.contains("35"), "Reusing the saved template must restore its time target")
        XCTAssertEqual(app.textFields["exerciseName"].value as? String, "Wall sit custom")
    }

    @MainActor func testCaptureReadmeScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-uitests", "--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["createRoutine"].waitForExistence(timeout: 5))
        capture("my-week", from: app)
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "libraryExercise.")).firstMatch.waitForExistence(timeout: 5))
        capture("exercise-library", from: app)
        app.tabBars.buttons.element(boundBy: 0).tap()
        app.buttons["createRoutine"].tap()
        app.buttons["addBlock"].tap()
        app.buttons["addExercise"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "catalogExercise.")).firstMatch.tap()
        XCTAssertTrue(app.segmentedControls["exerciseMeasurement"].waitForExistence(timeout: 5))
        capture("exercise-repetitions", from: app)
        app.segmentedControls["exerciseMeasurement"].buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.steppers["exerciseDuration"].exists)
        capture("exercise-time", from: app)
        app.segmentedControls["exerciseMeasurement"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.steppers["exerciseRepetitions"].exists, "The measurement control must toggle in both directions")
    }

    @MainActor private func capture(_ name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
