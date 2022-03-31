//
//  TimerDuration+CoreDataProperties.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 12.01.2022.
//
//

import Foundation
import CoreData


extension TimerDuration {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimerDuration> {
        return NSFetchRequest<TimerDuration>(entityName: "TimerDuration")
    }

    @NSManaged public var color: String?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Float
    @NSManaged public var id: String?
    @NSManaged public var timer: CT?

}

extension TimerDuration : Identifiable {

}
