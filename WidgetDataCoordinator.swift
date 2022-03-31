//
//  File.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 24.06.2021.
//

import Foundation
import CoreData

struct WidgetDataCoordinator {
    enum State:String {
        case brandNew
        case running
        case paused
        case zeroTimer
    }
    
    struct WidgetData:Identifiable, Equatable {
        static func == (lhs: WidgetDataCoordinator.WidgetData, rhs: WidgetDataCoordinator.WidgetData) -> Bool {
            lhs.id == rhs.id
        }
        
        var id:String
        var color:String
        let stickyNote:String
        var state:State
        let isCalendarEnabled:Bool
        
        let isTimer:Bool
        let referenceClock:TimeInterval
        var currentClock:TimeInterval
        let lastStartdate:Date?
        
        let sessionCount:Int
    }
    
    // MARK: - regular widget
    static let dummyWData = WidgetData(id: String.empty,
                                       color: "Charcoal",
                                       stickyNote: "Dummy",
                                       state: .brandNew,
                                       isCalendarEnabled: false,
                                       isTimer: false,
                                       referenceClock: 0.0,
                                       currentClock: 0.0,
                                       lastStartdate: nil,
                                       sessionCount: 0)
    
    static func zeroTimerData(from wData:WidgetDataCoordinator.WidgetData) -> WidgetData {
        var wDataCopy = wData
        wDataCopy.id = "000"
        wDataCopy.state = .zeroTimer
        wDataCopy.color = wData.color
        return wDataCopy
    }
    
    static func widgetData(from timeBubbleID:String?) -> WidgetData {
        guard let id = timeBubbleID else { return dummyWData }
        
        //grab timeBubble from CoreData
        let request:NSFetchRequest<CT> = CT.fetchRequest()
        guard
            let timeBubbles = try? CoreDataStack.shared.viewContext.fetch(request),
            let timeBubble = timeBubbles.filter({ $0.id?.uuidString == id }).first
        else { return dummyWData }
        
        //populate wData
        let timeBubbleState:State
        let lastStartDate = (timeBubble.currentSession?._pairs.last?.start)
        
        switch timeBubble.state {
        case .brandNew: timeBubbleState = .brandNew
        case .paused: timeBubbleState = .paused
        case .running: timeBubbleState = .running
        case .zeroTimer: timeBubbleState = .zeroTimer
        }
        
        let widgetData = WidgetData(id: timeBubble.id?.uuidString ?? String.empty,
                                    color: timeBubble.color ?? "Charcoal",
                                    stickyNote: timeBubble.stickyNote,
                                    state: timeBubbleState,
                                    isCalendarEnabled: timeBubble.isCalendarEnabled,
                                    
                                    //⚠️ very important
                                    isTimer: timeBubble.isTimer,
                                    referenceClock: TimeInterval(timeBubble.referenceClock),
                                    currentClock: TimeInterval(timeBubble.currentClock),
                                    lastStartdate: lastStartDate,
                                    sessionCount: timeBubble.bubbleSessions.count)
        
        return widgetData
    }
}
