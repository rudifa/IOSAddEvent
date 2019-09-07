//
//  MainViewController.swift
//  IOSAddEvent
//
//  Created by Eric PAJOT on 13.07.19.
//  Copyright © 2019 Eric PAJOT. All rights reserved.
//

import EventKit
import UIKit

class MainViewController: UIViewController {
    var userName = "rf" // EP'S

    @IBOutlet var calendarSelector: UITextField!

    let calEventManager = CalEventManager()
    var selectedCalendarTitle = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        let calendarTitles = calEventManager.getCalendars().map({ $0.title })
        calendarSelector.loadDropdownData(data: calendarTitles, selectionHandler: onSelect)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender _: Any?) -> Bool {
        if identifier == "segueToCalEventsTableViewController" {
            guard calEventManager.getCalendar(title: selectedCalendarTitle) != nil else {
                printClassAndFunc(info: "calendar \(selectedCalendarTitle) not found")
                return false
            }
            printClassAndFunc(info: "calendar \(selectedCalendarTitle) found")
            return true
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "segueToCalEventsTableViewController" {
            let destination = segue.destination as! CalEventsTableViewController
            guard let calendar = calEventManager.getCalendar(title: selectedCalendarTitle) else { return }
            let events = calEventManager.getEvents(calendar: calendar)
            destination.eventStringData = events.map({ $0.brief })
            destination.title = selectedCalendarTitle
        }
    }

    func onSelect(selectedText: String) {
        printClassAndFunc(info: "selected: \(selectedText)")
        selectedCalendarTitle = selectedText
    }

    @IBOutlet var calendarTitle: UITextField!

    @IBAction func showEvents(_: Any) {}

    @IBAction func unwindSegueToMainViewController(_: UIStoryboardSegue) {
        printClassAndFunc(info: "unwind segue")
    }

    @IBAction func addEventBtnPressed(_: Any) {
        let calEventManager = CalEventManager()
        calEventManager.insertCalEvent(userName: "rf+1", calendarTitle: "Code_Cal") { result in
            var message = ""
            switch result {
            case let .success(event):
                self.printClassAndFunc(info: "success: \(event.brief)")
                message = "\(event.brief)"
                break
            case let .failure(error):
                self.printClassAndFunc(info: "error: \(error)")
                message = "Error: \(error)"
                break
            }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Add event", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }

    @IBAction func addEventBtnPressed_0(_: Any) {
        let eventStore = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            insertEvent(store: eventStore)
        case .denied:
            printClassAndFunc(info: "Access denied")
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted: Bool, _: Error?) -> Void in
                if granted {
                    self!.insertEvent(store: eventStore)
                } else {
                    self?.printClassAndFunc(info: "Access denied")
                }
            })
        default:
            printClassAndFunc(info: "Case default")
        }
    }

    func insertEvent(store: EKEventStore) {
        let calendars = store.calendars(for: .event)

        for calendar in calendars {
//            printClassAndFunc(info: "Calendar\(calendar.title)")
            if calendar.title == "Code_Cal" {
                let startDate = Date()
                let endDate = startDate.addingTimeInterval(1 * 60 * 60)
                let event = EKEvent(eventStore: store)
                event.calendar = calendar

                event.title = userName // EP
                event.startDate = startDate
                event.endDate = endDate
                do {
                    try store.save(event, span: .thisEvent)
                } catch {
                    printClassAndFunc(info: "Error saving event in calendar")
                }
            }
        }
    }

    // EP's Try

    @IBAction func addCalBtnPressed(_: Any) {
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
            navigationController?.popViewController(animated: true)
            // self.dismiss(animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Calendar could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            navigationController?.popViewController(animated: true)
            // self.present(alert, animated: true, completion: nil)
        }
    }
}
