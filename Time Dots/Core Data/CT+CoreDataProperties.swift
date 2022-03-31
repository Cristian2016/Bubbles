//
//  CT+CoreDataProperties.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 12.01.2022.
//
//

import Foundation
import CoreData

extension CT {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CT> {
        return NSFetchRequest<CT>(entityName: "CT")
    }

    @NSManaged public var calendarStickerState: Int16
    @NSManaged public var color: String?
    @NSManaged public var created: Date?
    @NSManaged public var currentClock: Float
    @NSManaged public var durationVisible: Bool
    @NSManaged public var hasSquareWidget: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var isCalendarEnabled: Bool
    @NSManaged public var offlineAt: Date?
    @NSManaged public var rank: Int32
    @NSManaged public var referenceClock: Float
    @NSManaged public var running: Bool
    @NSManaged public var stateCD: String?
    @NSManaged public var stickyNote: String
    @NSManaged public var stickyNoteVisible: Bool
    @NSManaged public var sessions: NSOrderedSet?
    @NSManaged public var timerDurations: NSSet?
    
    @NSManaged public var stickies: NSOrderedSet?
}

extension CT {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: Session)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: Session)
}

extension CT {

    @objc(addTimerDurationsObject:)
    @NSManaged public func addToTimerDurations(_ value: TimerDuration)

    @objc(removeTimerDurationsObject:)
    @NSManaged public func removeFromTimerDurations(_ value: TimerDuration)
}

extension CT {

    @objc(removeObjectFromStickiesAtIndex:)
    @NSManaged public func removeFromStickies(at idx: Int)

    @objc(removeStickiesAtIndexes:)
    @NSManaged public func removeFromStickies(at indexes: NSIndexSet)

    @objc(addStickiesObject:)
    @NSManaged public func addToStickies(_ value: Sticky)

    @objc(removeStickiesObject:)
    @NSManaged public func removeFromStickies(_ value: Sticky)
}


extension CT : Identifiable { }
