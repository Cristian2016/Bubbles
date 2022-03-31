//
//  IntentHandler.swift
//  IntentExtension
//
//  Created by Cristian Lapusan on 18.06.2021.
//

//TimeBubble is the custom type created in the DynamicTimeBubbleSelection.intent

import Intents
import UIKit
import CoreData

extension IntentHandler {
    typealias Collection = INObjectCollection<TimeBubble>
    typealias Intent = DynamicTimeBubbleSelectionIntent
    typealias Arg = (Collection?, Error?) -> Void
}

class IntentHandler: INExtension, DynamicTimeBubbleSelectionIntentHandling {
    func provideTimeBubbleOptionsCollection(for intent: Intent, with completion: @escaping Arg) {
    
    //map WData to Bubble and then put data in a collection
    let collection = INObjectCollection(items: bubblesFromCoreData())
    
    //pass collection to completion handler
    completion(collection, nil)
}
    
    override func handler(for intent: INIntent) -> Any? {
        return self
    }
    
    // MARK: - helper
    //super important!
    private func bubblesFromCoreData() -> [TimeBubble] {
        
        var bucket = [TimeBubble]() //grab a bucket
        
        let request:NSFetchRequest<CT> = CT.fetchRequest()
        do {
            let cts = try CoreDataStack.shared.updateContext.fetch(request)
            cts.forEach {
                let id = $0.id?.uuidString
                let color = $0.color ?? "ok"
                let kind = $0.isTimer ? " Timer" : " Stopwatch"
                let title = $0.stickyNote.isEmpty ? "\(color)・" : "\(color)・" + $0.stickyNote
                let subtitle = $0.isTimer ? "Duration " + TimeInterval($0.referenceClock).timeAsString() : nil
                let imageName = color.replacingOccurrences(of: String.space, with: String.empty)
                let image = INImage(named: imageName)
                
                let bubble = TimeBubble(identifier: id,
                                        display: title + kind,
                                        subtitle: subtitle,
                                        image: image)
                
                bucket.append(bubble) //fill the bucket
            }
        } catch let error { print(error.localizedDescription) }
        
        return bucket //here's the filled bucket!
    }
}
