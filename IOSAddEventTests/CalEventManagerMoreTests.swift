//
//  CalEventManagerMoreTests.swift 0.3.0
//  IOSAddEventTests
//
//  Created by Rudolf Farkas on 18.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit
import XCTest

class CalEventManagerMoreTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {
        // restore to the normal state
        CalEventManager.shared.AUTHORIZATION_DENIED_FOR_TESTING = false
    }

    let defaultResult = Result<Bool, CalEventError>.failure(.unexpectedError)

    /* We are testing here the behavior of private functions execute:block:completion and executeAndThrow:block:completion

     For these test we have two CalEventManager instance methods which try to get authorization via getAuthorization and then execute one of trivial actions

     .execute_testCase:input:completion             // succeed, fail
     .executeAndThrow_testCase:input:completion     // succeed, fail, throw

     .execute:block:completion
        getAuthorization succeeds, code in block succeeds
        getAuthorization fails
        getAuthorization succeeds, code in block fails

     .executeAndThrow_testCase:input:completion
        getAuthorization succeeds, code in block succeeds
        getAuthorization fails
        getAuthorization succeeds, code in block fails
        getAuthorization succeeds, code in block throws
     */

    func test_execute_testCase_authorized_ok() {
        // given
        let expectation = self.expectation(description: "test_execute_testCase_authorized_ok")
        var testResult = defaultResult

        // when
        CalEventManager.shared.execute_testCase(input: "ok") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.success(true))
    }

    func test_execute_testCase_notAuthorized_ok() {
        // given
        CalEventManager.shared.AUTHORIZATION_DENIED_FOR_TESTING = true
        let expectation = self.expectation(description: "test_execute_testCase_notAuthorized_ok")
        var testResult = defaultResult

        // when
        CalEventManager.shared.execute_testCase(input: "ok") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 3)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.accessDenied))
    }

    func test_execute_testCase_authorized_fail() {
        // given
        let expectation = self.expectation(description: "test_execute_testCase_authorized_fail")
        var testResult = defaultResult

        // when
        CalEventManager.shared.execute_testCase(input: "fail!") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.expectedFailure))
    }

    func test_executeAndThrow_authorized_ok() {
        // given
        let expectation = self.expectation(description: "test_executeAndThrow_authorized_ok")
        var testResult = defaultResult

        // when
        CalEventManager.shared.executeAndThrow_testCase(input: "ok") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.success(true))
    }

    func test_executeAndThrow_notAuthorized_ok() {
        // given
        CalEventManager.shared.AUTHORIZATION_DENIED_FOR_TESTING = true
        let expectation = self.expectation(description: "test_executeAndThrow_notAuthorized_ok")
        var testResult = defaultResult

        // when
        CalEventManager.shared.executeAndThrow_testCase(input: "ok") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.accessDenied))
    }

    func test_executeAndThrow_authorized_fail() {
        // given
        let expectation = self.expectation(description: "test_executeAndThrow_authorized_fail")
        var testResult = defaultResult

        // when
        CalEventManager.shared.executeAndThrow_testCase(input: "fail!") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.expectedFailure))
    }

    func test_executeAndThrow_authorized_throw() {
        // given
        let expectation = self.expectation(description: "test_executeAndThrow_authorized_fail")
        var testResult = defaultResult

        // when
        CalEventManager.shared.executeAndThrow_testCase(input: "throw!") { result in
            testResult = result
            expectation.fulfill()
        }

        // then
        waitForExpectations(timeout: 30)
        XCTAssertEqual(testResult, Result<Bool, CalEventError>.failure(.thrownErrorCaught))
    }
}
