//
//  Session+CoreDataClass.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Thu  25.03.2021.
//
//

import Foundation
import CoreData

///TimeBubble Session
public class Session: NSManagedObject {
    enum TapKind {
        case start
        case pausex
    }
    
    private enum PairsState {
        case noPairsYet
        case lastPairNotClosed
        case lastPairClosed
    }
    
    private var pairsState:PairsState {
        if _pairs.isEmpty { return .noPairsYet }
        return _pairs.last!.stop == nil ?
            .lastPairNotClosed : .lastPairClosed
    }
    
    // MARK: - public methods
    var _pairs:[Pair] { pairs?.array as? [Pair] ?? [] }
    
    var isLastPairClosed:Bool { _pairs.last?.stop == nil ? false : true }
    
    ///either make new pair or close last pair
    func updatePairs(_ date:Date?) {
        switch pairsState {
        case .noPairsYet, .lastPairClosed:
            let newPair = Pair(context: self.managedObjectContext!)
            newPair.start = Date()
            newPair.session = self
            
        case .lastPairNotClosed:
            let lastPair = _pairs.last!
            lastPair.stop = (date != nil) ? date! : Date()
            lastPair.duration = Float(lastPair.stop!.timeIntervalSince(lastPair.start!))
        }
        
        CoreDataStack.shared.saveContext()
    }
    
    ///total duration of session (all pairs)
    func totalDuration() -> TimeInterval {
        guard !_pairs.isEmpty else { return 0 }
        
        var bucket = TimeInterval(0)
        _pairs.forEach { bucket += TimeInterval($0.duration) }
        return bucket
    }
}
