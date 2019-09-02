//
//  ViewController.swift
//  IOSAddEvent
//
//  Created by Eric PAJOT on 13.07.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit
import UIKit

class ViewController: UIViewController {
    var userName = "ep" // EP'S

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func addResaBtnPressed(_ sender: Any) {
        // 1
        let eventStore = EKEventStore()

        // 2
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            self.insertEvent(store: eventStore)
        case .denied:
            print("Access denied")
        case .notDetermined:
            // 3
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted: Bool, _: Error?) -> Void in
                if granted {
                    self!.insertEvent(store: eventStore)
                } else {
                    print("Access denied")
                }
            })
        default:
            print("Case default")
        }
    }

    func insertEvent(store: EKEventStore) {
        // 1
        let calendars = store.calendars(for: .event)

        for calendar in calendars {
            // 2
            print("\(calendar.title)")
            if calendar.title == "Code_Cal" {
                // 3
                let startDate = Date()
                // 1 hours
                let endDate = startDate.addingTimeInterval(1 * 60 * 60)

                // 4
                let event = EKEvent(eventStore: store)
                event.calendar = calendar

                event.title = userName // EP
                event.startDate = startDate
                event.endDate = endDate

                // 5
                do {
                    try store.save(event, span: .thisEvent)
                } catch {
                    print("Error saving event in calendar") }
            }
        }
    }

    // EP's Try

    @IBAction func addCalBtnPressed(_ sender: Any) {
        // Create an Event Store instance
        let eventStore = EKEventStore()

        // Use Event Store to create a new calendar instance
        // Configure its title
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)

        // Probably want to prevent someone from saving a calendar
        // if they don't type in a name...
        newCalendar.title = "Code_Cal_01"

        // Access list of available sources from the Event Store
        let sourcesInEventStore = eventStore.sources

        // Filter the available sources and select the "Local" source to assign to the new calendar's
        // source property
        newCalendar.source = sourcesInEventStore.filter {
            (source: EKSource) -> Bool in
            source.sourceType.rawValue == EKSourceType.local.rawValue
        }.first!

        // Save the calendar using the Event Store instance
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
            self.navigationController?.popViewController(animated: true)
            // self.dismiss(animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Calendar could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.navigationController?.popViewController(animated: true)
            // self.present(alert, animated: true, completion: nil)
        }
    }
}
