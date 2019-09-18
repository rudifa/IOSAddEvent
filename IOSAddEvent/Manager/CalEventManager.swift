//
//  CalEventManager.swift v.0.3.1
//  IOSAddEvent
//
//  Created by Rudolf Farkas on 05.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit

extension EKAuthorizationStatus {
    public var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
            @unknown default:
            fatalError()
        }
    }
}

enum CalEventError: Error {
    case accessDenied
    case calendarNotFound
    case noEventsFoundInCalendar
    case failedToSaveEventInCalendar
    case unknownError
    case unexpectedError
    case thrownErrorCaught
    case expectedFailure // for teesting
}

extension EKEvent {
    var brief: String {
        var brf = ""
        if title != nil { brf += title }
        if startDate != nil { brf += " \(startDate!.EEEE_ddMMyyyy_HHmmss)" }
        if endDate != nil { brf += " to \(endDate!.EEEE_ddMMyyyy_HHmmss)" }
        if calendar != nil { brf += " in \(calendar!.title)" }
        return "\(brf)"
    }
}

extension EKEventStore {
    func makeEvent(title: String, startDate: Date = Date(), endDate: Date = Date().incremented(by: .hour, times: 1)) -> EKEvent {
        let event = EKEvent(eventStore: self)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        return event
    }
}

/// Wrapper over EventKit
class CalEventManager: NSObject {
    static let shared = CalEventManager()

    let eventStore = EKEventStore()

    var AUTHORIZATION_DENIED_FOR_TESTING = false

    private override init() {
        super.init()
    }

    // MARK: - new style methods, using execute block

    private func getAuthorization(completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        if AUTHORIZATION_DENIED_FOR_TESTING {
            completion(.failure(.accessDenied))
            return
        }
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            completion(.success(true))
        case .denied:
            completion(.failure(.accessDenied))
        case .notDetermined:
            eventStore.requestAccess(to: .event) { (granted: Bool, _: Error?) -> Void in
                if granted {
                    completion(.success(true))
                } else {
                    completion(.failure(.accessDenied))
                }
            }
        default:
            completion(.failure(.unknownError))
        }
    }

    /// Find all calendars known to the event store
    ///
    /// - Parameter completion: reports a Result containing the calendars or an error
    func getCalendars(completion: @escaping ((Result<[EKCalendar], CalEventError>) -> Void)) {
        execute(block: {
            let calendars = self.eventStore.calendars(for: .event)
            completion(.success(calendars))
        }) { result in
            switch result {
            case .success:
                completion(.failure(.unexpectedError))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Find calendar by its title
    ///
    /// - Parameters:
    ///   - title: calendar ttle
    ///   - completion: reports a Result containing the calendar or an error
    func getCalendar(title: String, completion: @escaping ((Result<EKCalendar, CalEventError>) -> Void)) {
        // getCalendars makes sure that we are authorized
        getCalendars { result in
            switch result {
            case let .success(calendars):
                self.printClassAndFunc(info: "calendars: \(calendars.map({ $0.title }))")
                if let calendar = calendars.filter({ $0.title == title }).first {
                    completion(.success(calendar))
                } else {
                    completion(.failure(.calendarNotFound))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Get events from calendar
    ///
    /// - Parameter title: calendar title
    ///   - completion: reports a Result containing the events or an error
    func getEventsFrom(calendar title: String, completion: @escaping ((Result<[EKEvent], CalEventError>) -> Void)) {
        // getCalendar -> getCalendars makes sure that we are authorized
        getCalendar(title: title) { result in
            switch result {
            case let .success(calendar):
                let events = self.getEvents(calendar: calendar)
                completion(.success(events))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - old style methods reused

    /// Load events from calendar
    ///
    /// Note: returns events within the year 2109, for now
    ///
    /// - Parameter calendar: target calendar
    func getEvents(calendar: EKCalendar) -> [EKEvent] {
        // Create a date formatter instance to use for converting a string to a date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Create start and end date NSDate instances to build a predicate for which events to select
        let startDate = dateFormatter.date(from: "2019-01-01")
        let endDate = dateFormatter.date(from: "2019-12-31")

        if let startDate = startDate, let endDate = endDate {
            // Use an event store instance to create a NSPredicate
            let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])

            // Use the configured NSPredicate to find and return events in the store that match
            let events = eventStore.events(matching: eventsPredicate).sorted {
                (e1: EKEvent, e2: EKEvent) -> Bool in
                return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedDescending
            }
            return events
        }
        return []
    }

    // TODO: PHASE OUT THIS METHOD
    /// Insert event into calendar
    ///
    /// - Parameters:
    ///   - title: event title
    ///   - calendarTitled: calendar title, e.g. "Code_Cal"
    func addEvent(title: String, into calendarTitled: String, completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        printClassAndFunc(info: ">")
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date()
        event.endDate = event.startDate.addingTimeInterval(2 * 60 * 60)
        addEvent(event: event, into: calendarTitled, completion: completion)
    }

    /// Insert event into calendar
    ///
    /// - Parameters:
    ///   - event: event to add
    ///   - calendarTitled: target calendar title
    ///   - completion: reports success or error
    func addEvent(event: EKEvent, into calendarTitled: String, completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        printClassAndFunc(info: ">")
        getCalendar(title: calendarTitled) { getCalResult in
            switch getCalResult {
            case let .success(calendar):
                self.execute(block: {
                    event.calendar = calendar
                    do {
                        try self.eventStore.save(event, span: .thisEvent)
                        completion(.success(true))
                    } catch {
                        completion(.failure(.failedToSaveEventInCalendar))
                    }
                }) { execResult in
                    switch execResult {
                    case let .success(ok):
                        self.printClassAndFunc(info: "execResult: \(ok)")
                    case let .failure(error):
                        self.printClassAndFunc(info: "execResult: \(error)")
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - new style authorization helpers

    /// Executes the code block (closure) iff the authorization is available
    ///
    /// - Parameters:
    ///   - block: code to execute
    ///   - completion: reports a Result containing the success or an error
    private func execute(block: @escaping (() -> Void), completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        getAuthorization { authorizationResult in
            switch authorizationResult {
            case .success:
                block()
            case let .failure(authorizationError):
                completion(.failure(authorizationError))
            }
        }
    }

    /// Executes the code block (closure) that may throw, iff the authorization is available
    ///
    /// - Parameters:
    ///   - block: code to execute
    ///   - completion: reports a Result containing the success or an error
    private func executeAndThrow(block: @escaping (() throws -> Void), completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        getAuthorization { authorizationResult in
            switch authorizationResult {
            case .success:
                do {
                    try block()
                } catch {
                    completion(.failure(.thrownErrorCaught))
                }
            case let .failure(authorizationError):
                completion(.failure(authorizationError))
            }
        }
    }

    // MARK: - for use in unit tests only

    /// Test authorization
    ///
    /// - Parameter completion: reports success or failure of getAuthorization
    func checkAuthorization_testCase(completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        execute(block: {
            self.printClassAndFunc(info: "Hello there, just checking authorization")
            completion(.success(true))
        }) {
            result in completion(result)
        }
    }

    /// Test case for unit tests - code in block may succeed or fail
    ///
    /// - Parameters:
    ///   - input: "fail!" or any
    ///   - completion: reports success or failure
    func execute_testCase(input: String, completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        CalEventManager.shared.execute(block: {
            switch input {
            case "fail!":
                completion(.failure(.expectedFailure))
            default:
                completion(.success(true))
            }
        }) {
            // pass on the result - it may contain an authorization failure
            result in completion(result)
        }
    }

    /// Test case for unit tests - code in block may succeed, fail or throw
    ///
    /// - Parameters:
    ///   - input: "fail!", "throw!" or any
    ///   - completion: reports success or failure
    func executeAndThrow_testCase(input: String, completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        func throwAlways() throws {
            throw CalEventError.unknownError
        }

        CalEventManager.shared.executeAndThrow(block: {
            switch input {
            case "fail!":
                completion(.failure(.expectedFailure))
            case "throw!":
                try throwAlways()
            default:
                completion(.success(true))
            }
        }) {
            // pass on the result - it may contain an authorization failure
            result in completion(result)
        }
    }
}
