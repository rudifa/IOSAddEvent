//
//  CalEventManager.swift v.0.2.0
//  IOSAddEvent
//
//  Created by Rudolf Farkas on 05.09.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit

enum CalEventError: Error {
    case accessDenied
    case calendarNotFound
    case failedToSaveEventInCalendar
    case unknownError
}

extension EKEvent {
    var brief: String {
        var brf = ""
        if self.title != nil { brf += self.title }
        if self.startDate != nil { brf += " \(self.startDate!)" }
        if self.endDate != nil { brf += " to \(endDate!)" }
        if self.calendar != nil { brf += " in \(calendar!.title)" }
        return "\(brf)"
    }
}

/// Wrapper over EventKit
class CalEventManager: NSObject {
    /// Check authorization for adding calendar events and insert event into calendar
    ///
    /// - Parameters:
    ///   - userName: user name
    ///   - calendarTitle: calendar title, e.g. "Code_Cal"
    func insertCalEvent(userName: String, calendarTitle: String, completion: @escaping ((Result<EKEvent, CalEventError>) -> Void)) {
        //        printClassAndFunc(info: "")

        let eventStore = EKEventStore()

        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            insertEvent(store: eventStore, userName: userName, calendarTitle: calendarTitle, completion: completion)
        case .denied:
            //            printClassAndFunc(info: "Access denied")
            completion(.failure(.accessDenied))
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: { (granted: Bool, _: Error?) -> Void in
                if granted {
                    self.insertEvent(store: eventStore, userName: userName, calendarTitle: calendarTitle, completion: completion)
                } else {
                    //                    self?.printClassAndFunc(info: "Access denied")
                    completion(.failure(.accessDenied))
                }
            })
        default:
            //            printClassAndFunc(info: "Case default")
            completion(.failure(.unknownError))
        }
    }

    /// Insert event into calendar
    ///
    /// - Parameters:
    ///   - userName: user name
    ///   - calendarTitle: calendar title, e.g. "Code_Cal"
    private func insertEvent(store: EKEventStore, userName: String, calendarTitle: String, completion: ((Result<EKEvent, CalEventError>) -> Void)) {
        //        printClassAndFunc(info: "")

        let calendars = store.calendars(for: .event)

        for calendar in calendars {
            //            printClassAndFunc(info: "Calendar\(calendar.title)")
            if calendar.title == calendarTitle {
                let startDate = Date()
                let endDate = startDate.addingTimeInterval(2 * 60 * 60)

                let event = EKEvent(eventStore: store)
                event.calendar = calendar

                event.title = userName
                event.startDate = startDate
                event.endDate = endDate

                do {
                    try store.save(event, span: .thisEvent)
                    //                    printClassAndFunc(info: "Success saving event in calendar")
                    completion(.success(event))
                    return
                } catch {
                    //                    printClassAndFunc(info: "Error saving event in calendar")
                    completion(.failure(.failedToSaveEventInCalendar))
                    return
                }
            }
        }
        //        printClassAndFunc(info: "Calendar not found")
        completion(.failure(.calendarNotFound))
    }
}

