//
//  ExampleUITests.swift
//  ExampleUITests
//
//  Created by dsp on 17/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import XCTest

class ExampleUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCoverage() {
        XCUIApplication().launch()
         DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            XCTAssert(false)
        }
    }
}
