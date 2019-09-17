//
//  IOSAddEventTests.swift
//  IOSAddEventTests
//
//  Created by Rudolf Farkas on 17.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import XCTest

class IOSAddEventTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {}

    func test_checkAuthorization() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_checkAuthorization")
        var passed = false

        // when
        calEventmanager.checkAuthorization { result in
            switch result {
            case .success:
                passed = true
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(passed)
    }

    func test_getCalendars() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getCalendars")
        var count = -1

        // when
        calEventmanager.getCalendars { result in
            switch result {
            case let .success(calendars):
                count = calendars.count
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(count >= 0)
    }

    func test_getCalendar() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getCalendar")
        var title = ""

        // when
        calEventmanager.getCalendar(title: "Code_Cal") { result in
            switch result {
            case let .success(calendar):
                title = calendar.title
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(title, "Code_Cal")
    }

    func test_getEventsFromCalendar() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getEventsFromCalendar")
        var count = -1

        // when
        calEventmanager.getEventsFrom(calendar: "Code_Cal") { result in
            switch result {
            case let .success(events):
                count = events.count
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(count >= 0)
    }

    func test_addEvent() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getEventsFromCalendar")
        var success = false

        // when
        calEventmanager.addEvent(title: "from XCTest", into: "Code_Cal") { result in
            switch result {
            case .success:
                success = true
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(success)
    }
}
