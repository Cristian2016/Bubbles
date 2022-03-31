//
//  Pair+CoreDataProperties.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 18.05.2021.
//
//

import Foundation
import CoreData

extension Pair {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pair> {
        return NSFetchRequest<Pair>(entityName: "Pair")
    }
    @NSManaged public var start: Date?
    @NSManaged public var stop: Date?
    @NSManaged public var duration: Float
    
    @NSManaged public var sticky: String
    @NSManaged public var isStickyVisible: Bool
    
    @NSManaged public var session: Session?
}

extension Pair : Identifiable {

}
