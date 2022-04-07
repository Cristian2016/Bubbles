//
//  BubbleSticky+CoreDataProperties.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 06.04.2022.
//
//

import Foundation
import CoreData


extension BubbleSticky {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BubbleSticky> {
        return NSFetchRequest<BubbleSticky>(entityName: "BubbleSticky")
    }

    @NSManaged public var created: Date?
    @NSManaged public var content: String?

}

extension BubbleSticky : Identifiable {

}
