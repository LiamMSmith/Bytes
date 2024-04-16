//
//  CalVC.swift
//  Bytes2
//

import UIKit
import FSCalendar
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class CalVC: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
    
    var calendar: FSCalendar!
    var formatter = DateFormatter()
    var recordedDates: [Date] = []

    @IBOutlet weak var memoriesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateRecordedDates()

        let calendarSize: CGFloat = 350
        let calendarContainer = UIView(frame: CGRect(x: (self.view.frame.size.width - calendarSize) / 2, y: (self.view.frame.size.height - calendarSize) / 2, width: calendarSize, height: calendarSize))
        calendarContainer.backgroundColor = UIColor.clear
        calendarContainer.layer.borderWidth = 2.0
        calendarContainer.layer.borderColor = UIColor(named: "bytesPurple")?.cgColor
        calendarContainer.layer.cornerRadius = 10.0
        calendarContainer.clipsToBounds = true
        let calendarPadding: CGFloat = 10.0
        let calendarFrame = CGRect(x: calendarPadding, y: calendarPadding, width: calendarContainer.bounds.width - 2 * calendarPadding, height: calendarContainer.bounds.height - 2 * calendarPadding)
        calendar = FSCalendar(frame: calendarFrame)
        calendarContainer.addSubview(calendar)
        self.view.addSubview(calendarContainer)
        
        // changing calendar fonts
        // calendar.appearance.titleFont =
        // calendar.appearance.headerTitleFont =
        // calendar.appearance.weekdayFont =
        
        calendar.appearance.todayColor = UIColor(named: "bytesGold")
        calendar.appearance.titleTodayColor = UIColor(named: "bytesBeige")
        calendar.appearance.titleDefaultColor = UIColor(named: "bytesPurple")
        calendar.appearance.headerTitleColor = UIColor(named: "bytesPurple")
        calendar.appearance.weekdayTextColor = UIColor(named: "bytesPurple")
        calendar.appearance.selectionColor = UIColor(named: "bytesPurple")
        calendar.appearance.eventDefaultColor = UIColor(named: "bytesGold")
        calendar.appearance.eventSelectionColor = UIColor(named: "bytesGold")
        calendar.appearance.eventOffset = CGPoint(x: 0, y: -7)

        // gets rid of today's date circle
        // calendar.today = nil
        
        calendar.dataSource = self
        calendar.delegate = self
        
        memoriesLabel.center.x = view.center.x
        let memoriesLabelHeight: CGFloat = 50.0
        let memoriesLabelY = (self.view.frame.size.height - calendarSize) / 2 - memoriesLabelHeight - 10.0
        memoriesLabel.frame = CGRect(x: 0, y: memoriesLabelY, width: view.frame.size.width, height: memoriesLabelHeight)
        memoriesLabel.textAlignment = .center
        view.addSubview(memoriesLabel)
    }
    
    // called when a date is selected
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)
        
        if self.recordedDates.contains(date) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "HistorySegue", sender: dateString)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HistorySegue",
           let dateString = sender as? String,
           let destinationVC = segue.destination as? HistoryVC {
            destinationVC.selectedDate = dateString
        }
    }
    
    // everything after this date is unclickable
    func maximumDate(for calendar: FSCalendar) -> Date {
        return Date()
    }
    
    // sets dates user did not record as unclickable
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        if self.recordedDates.contains(date) {
            return true
        } else {
            return false
        }
    }
    
    // puts event dots under all dates that user recorded for
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) ->
        Int {
        if self.recordedDates.contains(date) {
            return 1
        }
        return 0
    }
    
    func populateRecordedDates() {
        guard let userid = Auth.auth().currentUser?.uid else {
            print("No user ID")
            return
        }
        
        let db = Firestore.firestore()
        let userCalendarRef = db.collection("user_calendars").document(userid)
        userCalendarRef.getDocument(completion: { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                
                if let dateKeys = data?.keys {
                    for dateKey in dateKeys {
                        if let date = dateFormatter.date(from: dateKey) {
                            self.recordedDates.append(date)
                        }
                    }
                }
                
                // Reload the calendar data after populating recordedDates
                self.calendar.reloadData()
            }
        })
    }
}
