//
//  CalEventManagerTests.swift 0.3.0
//  CalEventManagerTests
//
//  Created by Rudolf Farkas on 17.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit
import XCTest

class CalEventManagerTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {
        // restore to the normal state
        CalEventManager.shared.AUTHORIZATION_DENIED_FOR_TESTING = false
    }

    let defaultResult = Result<Bool, CalEventError>.failure(.unexpectedError)

    func test_checkAuthorization() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_checkAuthorization")
        var testResult = defaultResult

        // when
        calEventmanager.checkAuthorization_testCase { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.success(true))
    }

    func test_getCalendars() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getCalendars")
        var count = -1
        var error: CalEventError?

        // when
        calEventmanager.getCalendars { result in
            switch result {
            case let .success(calendars):
                count = calendars.count
            case let .failure(ferror):
                error = ferror
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(count >= 0)
        XCTAssertNil(error)
    }

    func test_getCalendar() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getCalendar")
        var title = ""
        var error: CalEventError?

        // when
        calEventmanager.getCalendar(title: "Code_Cal") { result in
            switch result {
            case let .success(calendar):
                title = calendar.title
            case let .failure(ferror):
                error = ferror
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(title, "Code_Cal")
        XCTAssertNil(error)
    }

    func test_getEventsFromCalendar() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_getEventsFromCalendar")
        var count = -1
        var error: CalEventError?

        // when
        calEventmanager.getEventsFrom(calendar: "Code_Cal") { result in
            switch result {
            case let .success(events):
                count = events.count
            case let .failure(ferror):
                error = ferror
            }
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertTrue(count >= 0)
        XCTAssertNil(error)
    }

    func test_addEvent1() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_addEvent1")
        let date = Date()
        let event = calEventmanager.eventStore.makeEvent(title: "from test_addEvent1", startDate: date, endDate: date.incremented(by: .hour, times: 1))
        var testResult = defaultResult

        // when
        calEventmanager.addEvent(event: event, into: "Code_Cal") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.success(true))
    }

    func test_addEvent2() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_addEvent2")
        let date = Date()
        let event = calEventmanager.eventStore.makeEvent(title: "from test_addEvent3", startDate: date, endDate: date.incremented(by: .hour, times: 2))
        var testResult = defaultResult

        // when
        calEventmanager.addEvent(event: event, into: "No_Such_Calendar") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.calendarNotFound))
    }

    func test_addEvent3() {
        // given
        let calEventmanager = CalEventManager.shared
        let expectation = self.expectation(description: "test_addEvent3")
        let date = Date()
        let event = calEventmanager.eventStore.makeEvent(title: "from test_addEvent3", startDate: date, endDate: date.incremented(by: .hour, times: 3))
        var testResult = defaultResult

        // when
        calEventmanager.addEvent(event: event, into: "Code_Cal") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.success(true))
    }
}
