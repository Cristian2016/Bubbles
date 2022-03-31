//
//  CT+CoreDataProperties.swift
//  Time Dots
//
//  Created by Cristian Lăpușan on Sat  6.03.2021.
//
//

import Foundation
import CoreData


extension CT {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CT> {
        return NSFetchRequest<CT>(entityName: "CT")
    }

    @NSManaged public var color: String?
    @NSManaged public var created: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var needleCD: Float
    @NSManaged public var stateCD: String?
    @NSManaged public var stickyNote: String?
    @NSManaged public var stickyNoteVisible: Bool
    @NSManaged public var atomicClock: Float
    @NSManaged public var running: Bool
    @NSManaged public var offline: Date?
    @NSManaged public var timePoints: NSOrderedSet?

}

// MARK: Generated accessors for timePoints
extension CT {

    @objc(insertObject:inTimePointsAtIndex:)
    @NSManaged public func insertIntoTimePoints(_ value: TimePoint, at idx: Int)

    @objc(removeObjectFromTimePointsAtIndex:)
    @NSManaged public func removeFromTimePoints(at idx: Int)

    @objc(insertTimePoints:atIndexes:)
    @NSManaged public func insertIntoTimePoints(_ values: [TimePoint], at indexes: NSIndexSet)

    @objc(removeTimePointsAtIndexes:)
    @NSManaged public func removeFromTimePoints(at indexes: NSIndexSet)

    @objc(replaceObjectInTimePointsAtIndex:withObject:)
    @NSManaged public func replaceTimePoints(at idx: Int, with value: TimePoint)

    @objc(replaceTimePointsAtIndexes:withTimePoints:)
    @NSManaged public func replaceTimePoints(at indexes: NSIndexSet, with values: [TimePoint])

    @objc(addTimePointsObject:)
    @NSManaged public func addToTimePoints(_ value: TimePoint)

    @objc(removeTimePointsObject:)
    @NSManaged public func removeFromTimePoints(_ value: TimePoint)

    @objc(addTimePoints:)
    @NSManaged public func addToTimePoints(_ values: NSOrderedSet)

    @objc(removeTimePoints:)
    @NSManaged public func removeFromTimePoints(_ values: NSOrderedSet)

}

extension CT : Identifiable {

}
