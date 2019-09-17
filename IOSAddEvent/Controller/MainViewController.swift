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
    var userName = "rf add event"

    @IBOutlet var calendarSelector: UITextField!

    let calEventManager = CalEventManager.shared
    var selectedCalendarTitle = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        calEventManager.getCalendars { result in
            switch result {
            case let .success(calendars):
                DispatchQueue.main.async {
                    let calendarTitles = calendars.map({ $0.title })
                    self.calendarSelector.loadDropdownData(data: calendarTitles, selectionHandler: self.onSelect)
                }
            case let .failure(error):
                self.printClassAndFunc(info: "getCalendars error: \(error)")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        printClassAndFunc(info: "segue.identifier \(String(describing: segue.identifier))")
        if segue.identifier == "segueToCalEventsTableViewController" {
            let destination = segue.destination as! CalEventsTableViewController
            calEventManager.getEventsFrom(calendar: selectedCalendarTitle) { result in
                switch result {
                case let .success(events):
                    self.printClassAndFunc(info: "events.count= \(events.count)")
                    destination.eventStringData = events.map({ $0.brief })
                case let .failure(error):
                    self.printClassAndFunc(info: "error \(error)")
                }
            }
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
        let calEventManager = CalEventManager.shared
        calEventManager.addEvent(title: userName, into: "Code_Cal") { result in
            var message = ""
            switch result {
            case .success:
                self.printClassAndFunc(info: "success)")
                message = ""
            case let .failure(error):
                self.printClassAndFunc(info: "error: \(error)")
                message = "Error: \(error)"
            }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Add event", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
}
