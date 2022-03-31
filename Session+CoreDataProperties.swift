//
//  Session+CoreDataProperties.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 18.05.2021.
//
//

import Foundation
import CoreData


extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var created: Date?
    @NSManaged public var eventID: String?
    @NSManaged public var isEnded: Bool
    @NSManaged public var ct: CT?
    
    //replace time points with pairs
    @NSManaged public var pairs: NSOrderedSet?
}

// MARK: Generated accessors for pairs
extension Session {

    @objc(insertObject:inPairsAtIndex:)
    @NSManaged public func insertIntoPairs(_ value: Pair, at idx: Int)

    @objc(removeObjectFromPairsAtIndex:)
    @NSManaged public func removeFromPairs(at idx: Int)

    @objc(insertPairs:atIndexes:)
    @NSManaged public func insertIntoPairs(_ values: [Pair], at indexes: NSIndexSet)

    @objc(removePairsAtIndexes:)
    @NSManaged public func removeFromPairs(at indexes: NSIndexSet)

    @objc(replaceObjectInPairsAtIndex:withObject:)
    @NSManaged public func replacePairs(at idx: Int, with value: Pair)

    @objc(replacePairsAtIndexes:withPairs:)
    @NSManaged public func replacePairs(at indexes: NSIndexSet, with values: [Pair])

    @objc(addPairsObject:)
    @NSManaged public func addToPairs(_ value: Pair)

    @objc(removePairsObject:)
    @NSManaged public func removeFromPairs(_ value: Pair)

    @objc(addPairs:)
    @NSManaged public func addToPairs(_ values: NSOrderedSet)

    @objc(removePairs:)
    @NSManaged public func removeFromPairs(_ values: NSOrderedSet)

}

extension Session : Identifiable {

}
