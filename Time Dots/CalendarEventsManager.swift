//
//  CalendarEventsManager.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 08.05.2021.
//

import Foundation
import EventKit
import EventKitUI
import UIKit
import CoreLocation

extension CalendarEventsManager {
    typealias Store = EKEventStore
}

class CalendarEventsManager: NSObject {
    // MARK: -
    private lazy var store = Store() /* read write events */
    private(set) var defaultCalendarTitle = "Time Bubbles 📥"
    private let eventNotesSeparator = "Add notes below:\n"
    private lazy var defaultCalendarID = UserDefaults.standard.value(forKey: UDKey.defaultCalendarIdentifier) as? String
    
    // MARK: - public
    ///if authorization granted, create default calendar to add events to it
    func requestAuthorizationAndCreateCalendar() {
        guard
            Store.authorizationStatus(for: .event) != .authorized else { return }
        
        store.requestAccess(to: .event) { [weak self] /* access */ granted, error in
            guard let self = self else {return}
            if granted { self.createCalendarIfNeeded(with: self.defaultCalendarTitle) }
        }
    }
    
    private var doNotCreateCalendar = false
    
    ///⚠️ To avoid duplicates, this function creates a calendar only if there is no other calendar with same or similar name. if it finds an existing calendar, it will set it as the default calendar
    private func createCalendarIfNeeded(with title:String) {
        
        store.calendars(for: .event).forEach {
            //if there is a calendar with that name already or similar name, do not create a calendar
            if $0.title == defaultCalendarTitle
                || $0.title.lowercased().contains("time") && $0.title.lowercased().contains("bubble") {
                UserDefaults.standard.setValue($0.calendarIdentifier, forKey: UDKey.defaultCalendarIdentifier)
                doNotCreateCalendar = true
            }
        }
        
        if doNotCreateCalendar { return }
        
        //calendar creation
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = defaultCalendarTitle
        calendar.cgColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1).cgColor
        
        //ideal situation, iCloud calendar that syncs with all devices
        let calDAVSources = store.sources.filter { $0.sourceType == .calDAV }
        let calDAVAvailable = !calDAVSources.isEmpty
        
        if calDAVAvailable {
            calendar.source = calDAVSources.first! //use calDAV source for the calendar
            
        } else {//try to use a local source for the calendar
            
            let localSources = store.sources.filter { $0.sourceType == .local }
            if !localSources.isEmpty { calendar.source = localSources.first! }
            else {
                
            }
        }
        
        do {
            try store.saveCalendar(calendar, commit: true)
            UserDefaults.standard.setValue(calendar.calendarIdentifier, forKey: UDKey.defaultCalendarIdentifier)
        }
        catch { }
    }
    func shouldExportToCalendarAllSessions(of bubble:CT) {
        guard
            bubble.isCalendarEnabled,
            !bubble.bubbleSessions.isEmpty else { return }
        
        bubble.bubbleSessions.forEach { if $0.isEnded { createNewEvent(for: $0) }}
    }
    
    // MARK: - Events
    private func lastSubeventNote(for session:Session) -> String {
        session._pairs.last!.sticky
    }
    func createNewEvent(for session: Session) {
        guard
            session.isLastPairClosed,
            session.eventID == nil else { return }
        
        let pairs = session._pairs
        let firstPair = pairs.first!
        let lastPair = pairs.last!
        
        let notes = composeEventNotes(from: pairs)
        
        let title = title(for: session)
        session.eventID = newEvent(eventTitle: title, stickyNote:session.ct?.stickyNote, notes: notes, start: firstPair.start!, end: lastPair.stop!)
        CoreDataStack.shared.saveContext()
    }
    
    func updateEvent(_ kind:EventUpdateKind) {
        switch kind {
        case .notes(let session):
            guard
                let eventID = session.eventID,
                let event = store.event(withIdentifier: eventID),
                !session._pairs.isEmpty
            else { return }
            
            if let previousNotes = event.notes {
                let notesAddedInCalendarByTheUser = previousNotes.components(separatedBy: eventNotesSeparator).last!
                let notesAddedInTheApp = composeEventNotes(from: session._pairs)
                let updatedNotes = notesAddedInTheApp + notesAddedInCalendarByTheUser
                
                // FIXME: find a better implementation
                //change event title here only if the latest note has changed as well
                event.title = title(for: session)
                event.notes = updatedNotes
                
                do { try store.save(event, span: .thisEvent, commit: true) }
                catch { }
            }
            
        case /* update event */.title(let bubble):
            bubble.bubbleSessions.forEach {
                if
                    $0.isEnded,
                    let id = $0.eventID,
                    let event = store.event(withIdentifier: id) {
                    
                    event.title = title(for: $0)
                    do { try store.save(event, span: .thisEvent, commit: true) }
                    catch { }
                }
            }
        }
    }
    
    func deleteEvent(with id:String?) {
        guard
            let id = id,
            let event = store.event(withIdentifier: id)
        else { return }
        
        do { try store.remove(event, span: .thisEvent) }
        catch { }
    }
    
    func addNote(_ note:String, to event:EKEvent) {
        event.notes = note
    }
    
    // MARK: - new feature
    func newQuickActionEvent() {
        
        let event = EKEvent(eventStore: store)
        event.title = "Quick Action Event"
        
        //set event duration to 15 min
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(60*15)
        
        let defaultCalendarIdentifier = UserDefaults.standard.value(forKey: UDKey.defaultCalendarIdentifier) as? String
        
        if let calendar = store.calendars(for: .event).filter({$0.calendarIdentifier == defaultCalendarIdentifier}).first {
            event.calendar = calendar
        }
        else {
            createCalendarIfNeeded(with: defaultCalendarTitle)
            delayExecution(.now() + 2.0) {[weak self] in
                let calendar = self?.store.calendars(for: .event).filter({$0.calendarIdentifier == defaultCalendarIdentifier}).first
                event.calendar = calendar
            }
        }
        event.alarms = []
        
        do {
            try store.save(event, span: .thisEvent, commit: true)
        }
        catch let error {
            print(error.localizedDescription)
            return
        }
    }
    
    // MARK: - helpers
    private func dateInterval(start:Date, end:Date) -> String {
        let startDateString = DateFormatter.tbDateStyle.string(from: start)
        let endDateString = DateFormatter.tbDateStyle.string(from: end)
        let startAndEndAreTheSame = startDateString == endDateString
        return !startAndEndAreTheSame ? startDateString + " - " + endDateString : startDateString
    }
    
    private func timeInterval(start:Date, end:Date) -> String {
        let startTimeString = DateFormatter.tbTimeStyle.string(from: start)
        let endTimeString = DateFormatter.tbTimeStyle.string(from: end)
        
        return startTimeString + " - " + endTimeString
    }
    
    private func composeEventNotes(from pairs:[Pair]) -> String {
        var bucket = String.empty
        for (index, pair) in pairs.enumerated() {
            let note = (!pair.sticky.isEmpty ? pair.sticky : "Untitled")
            bucket += "◼︎ \(index + 1). " + note + "\n"
            
            //date interval
            bucket += dateInterval(start: pair.start!, end: pair.stop!)
            bucket += "\n"
            
            //time interval
            bucket += timeInterval(start: pair.start!, end: pair.stop!)
            bucket += "\n"
            
            //duration
            let stringDuration = TimeInterval(pair.duration).timeAsString()
            bucket += "Duration " + stringDuration
            
            bucket += "\n" + "\n"
        }
        
        bucket += eventNotesSeparator
        return bucket
    }
    
    private func newEvent(eventTitle:String?, stickyNote:String?, notes:String?, start:Date, end:Date) -> String? {
        let event = EKEvent(eventStore: store)
        event.title = eventTitle
        event.notes = notes
        event.startDate = start
        event.endDate = end
        
        if let calendar = suggestedCalendar(for: stickyNote) { event.calendar = calendar }
        else {//create Calendar if you can't find one
            createCalendarIfNeeded(with: defaultCalendarTitle)
            delayExecution(.now() + 2.0) {[weak self] in
                let calendar = self?.store.calendars(for: .event).filter({$0.calendarIdentifier == self?.defaultCalendarID}).first
                event.calendar = calendar
            }
        }
        
        event.alarms = []
        
        do {
            try store.save(event, span: .thisEvent, commit: true)
            return event.eventIdentifier
        }
        catch { return nil }
    }
    
    private func title(for session:Session) -> String {
        guard let bubble = session.ct else { return "No Title" }
        
        let stickyNote = bubble.stickyNote.isEmpty ? bubble.color! : bubble.stickyNote
        let colorEmoji = TricolorProvider.colorEmoji(bubble.color)
        
        let symbol:String
        switch bubble.kind {
        case .stopwatch: symbol = colorEmoji
        case .timer(limit: _): symbol = colorEmoji
        }
        
        let subeventsCount = String(session._pairs.count)
        let latestSubeventTitle = " " + session._pairs.last!.sticky
        
        let eventTitle = symbol + stickyNote + latestSubeventTitle + " ・\(subeventsCount)"
//        print(eventTitle)
        
        return eventTitle
    }
    
    private func isEventStillInTheCalendar(_ eventID:String) -> Bool {
        return false
    }
    
    // MARK: - helpers
    ///if stickynote matches a calendar already present in the Calendar App
    private func suggestedCalendar(for stickyNote:String?) -> EKCalendar? {
        guard let stickyNote = stickyNote else { return nil }
        
        let calendars = store.calendars(for: .event)
        let possibleCalendar = getAppropriateCalendar(from: calendars, for: stickyNote)
        
        return possibleCalendar ?? defaultCalendar()
    }
    private func defaultCalendar() -> EKCalendar? {
        store.calendars(for: .event).filter({$0.calendarIdentifier == defaultCalendarID}).first
    }
    
    private func getAppropriateCalendar(from calendars:[EKCalendar], for stickyNote:String) -> EKCalendar? {
        var calendar:EKCalendar? = nil
        let firstMatch = calendars.filter { $0.title.lowercased().contains(stickyNote.lowercased())}.first
        firstMatch?.title.split(separator: " ").forEach { split in
            if split.lowercased() == stickyNote.lowercased() {
                calendar = firstMatch
            }
        }
        return calendar
    }
    
    // MARK: -
    static let shared = CalendarEventsManager()
    private override init() {
        super.init()
    }
    
    // MARK: - enums and structs
    enum EventUpdateKind {
        case title(_ bubble:CT)
        case notes(_ session:Session)
    }
}
