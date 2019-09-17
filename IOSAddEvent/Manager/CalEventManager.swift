//
//  CalEventManager.swift v.0.3.0
//  IOSAddEvent
//
//  Created by Rudolf Farkas on 05.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit

extension EKAuthorizationStatus: CustomStringConvertible {
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
}

extension EKEvent {
    var brief: String {
        var brf = ""
        if title != nil { brf += title }
        if startDate != nil { brf += " \(startDate!)" }
        if endDate != nil { brf += " to \(endDate!)" }
        if calendar != nil { brf += " in \(calendar!.title)" }
        return "\(brf)"
    }
}

/// Wrapper over EventKit
class CalEventManager: NSObject {
    static let shared = CalEventManager()

    var eventStore = EKEventStore()
    var authorized = false

    private override init() {
        super.init()
//        updateAuthorization()
    }

    // MARK: - new style methods, using execute block

    private func getAuthorization(completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
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

    /// Test authorization
    ///
    /// - Parameter completion: reports success or failure of getAuthorization
    func checkAuthorization(completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        execute({
            self.printClassAndFunc(info: "Hello there, just checking authorization")
            completion(.success(true))
        }) {
            result in
            switch result {
            case let .success(ok):
                self.printClassAndFunc(info: "\(ok)")
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
            }
        }
    }

    /// Find all calendars known to the event store
    ///
    /// - Parameter completion: reports a Result containing the calendars or an error
    func getCalendars(completion: @escaping ((Result<[EKCalendar], CalEventError>) -> Void)) {
        execute({
            let calendars = self.eventStore.calendars(for: .event)
            self.printClassAndFunc(info: "calendars.count=\(calendars.count)")
            completion(.success(calendars))
        }) {
            result in
            switch result {
            case let .success(ok):
                self.printClassAndFunc(info: "\(ok)")
            case let .failure(error):
                self.printClassAndFunc(info: "\(error)")
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

    /// Insert event into calendar
    ///
    /// - Parameters:
    ///   - userName: user name
    ///   - calendarTitle: calendar title, e.g. "Code_Cal"
    func addEvent(title: String, into calendar: String, completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        printClassAndFunc(info: ">")
        getCalendar(title: calendar) { result in
            switch result {
            case let .success(calendar):
                self.execute({
                    let event = EKEvent(eventStore: self.eventStore)
                    event.calendar = calendar
                    event.title = title
                    event.startDate = Date()
                    event.endDate = event.startDate.addingTimeInterval(2 * 60 * 60)
                    do {
                        try self.eventStore.save(event, span: .thisEvent) // FAILS
                        completion(.success(true))
                    } catch {
                        completion(.failure(.failedToSaveEventInCalendar))
                    }
                }) { result in
                    switch result {
                    case let .success(ok):
                        self.printClassAndFunc(info: "\(ok)")
                    case let .failure(error):
                        self.printClassAndFunc(info: "\(error)")
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
    private func execute(_ block: @escaping (() -> Void), completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        getAuthorization { result in
            switch result {
            case .success:
                block()
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Executes the code block (closure) that may throw, iff the authorization is available
    ///
    /// - Parameters:
    ///   - block: code to execute
    ///   - completion: reports a Result containing the success or an error
    private func executeAndThrow(_ block: @escaping (() throws -> Void), completion: @escaping ((Result<Bool, CalEventError>) -> Void)) {
        getAuthorization { result in
            switch result {
            case .success:
                do {
                    try block()
                } catch {
                    completion(.failure(.unknownError))
                }
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
                return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
            }
            return events
        }
        return []
    }
}
