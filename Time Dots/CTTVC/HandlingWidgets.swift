//
//  HandlingWidgets.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 13.06.2021.
//

import UIKit
import WidgetKit
import SwiftUI

extension CTTVC {
    typealias DynamicIntent = DynamicTimeBubbleSelectionIntent
}

extension CTTVC {
    enum WidgetUpdateSituation:String {
        case unknown
        case userStart
        case userPause
        
        case /* user made a */ stickyNote
        case calendarEnable /* user enabled calendar */
        case systemEndSession /* timer reached zero */
        case userEndSession
    }
    
    internal func updateWidget(for bubble:CT, _ situation:WidgetUpdateSituation = .unknown) {
//        guard bubble.hasSquareWidget else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: "SquareWidget")
    }
    
    /// when app becomes active, check if any widgets added or removed. Bubbles with squareWidgets must be squared, bubbles with no squareWidgets must be round
    /// closure does not run on the main thread! ⚠️
    internal func matchBubblesToSquareWidgets() {
        WidgetCenter.shared.getCurrentConfigurations {[weak self] result in
            guard
                let self = self,
                let infos = try? result.get(),
                let bubbles = self.frc.fetchedObjects
            else { return }
            
            //both populated + unpopulated (empty) square widgets
            let squareWidgetInfos = infos.filter { $0.kind == "SquareWidget" }
            
            //get bubble.ids from squareWidgetInfos. Empty square widgets will be ignored
            var squareBubbleIDs = [String]()
            squareWidgetInfos.forEach {
                if
                    let bubble = ($0.configuration as? DynamicIntent)?.timeBubble,
                    let id = bubble.identifier {
                    squareBubbleIDs.append(id)
                }
            }
            
            let set0 = Set(squareBubbleIDs)/* coming from info */
            let allSquareBubbleIDs /* in CTTVC */ = set0.intersection(self.allBubblesIDs())
            
            DispatchQueue.main.async {
                bubbles.forEach {
                    let indexPath = self.frc.indexPath(forObject: $0)
                    let cell = self.getCell(for: indexPath?.row)
                    let isSquare = allSquareBubbleIDs.contains($0.id?.uuidString ?? String.empty)
                    
                    //change both the UI and the model
                    cell?.shapeShift(isSquare ? .square() : .circle )
                    $0.hasSquareWidget = isSquare ? true : false
                }
                
                //save CoreData context but it is saved many times already
//                CoreDataStack.shared.saveContext()
            }
        }
    }
}

// MARK: - helpers
extension CTTVC {
    internal func bubble(for id:String) -> CT? {
        frc.fetchedObjects?.filter { $0.id?.uuidString == id }.first
    }
    
    internal func allBubblesIDs() -> [String] {
        var bucket = [String?]()
        frc.fetchedObjects?.forEach({ bucket.append($0.id?.uuidString) })
        return bucket.compactMap { $0 }
    }
}
