//
//  Sticky+CoreDataProperties.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 19.03.2022.
//
//

import Foundation
import CoreData


extension Sticky {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sticky> {
        return NSFetchRequest<Sticky>(entityName: "Sticky")
    }

    @NSManaged public var content: String?
    @NSManaged public var created: Date?
    @NSManaged public var bubble: CT?

}

extension Sticky : Identifiable {

}
