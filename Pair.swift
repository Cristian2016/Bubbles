//
//  Pair+CoreDataClass.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 18.05.2021.
//
//

import Foundation
import CoreData

public class Pair: NSManagedObject {
    deinit {
//           print("Pair deinit")
       }
    
    var pairComplete:Bool {
        (start != nil) && (stop != nil)
    }
}
