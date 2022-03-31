//
//  SquareWidget.swift
//  SquareWidget
//
//  Created by Cristian Lapusan on 16.06.2021.
// ⚠️1. I assigned the second entry a different id from the original one to make it work!

import Foundation
import WidgetKit
import SwiftUI
import CoreData

extension LockedWProvider {
    typealias Intent = DynamicTimeBubbleSelectionIntent
    typealias Coordinator = WidgetDataCoordinator
}

// MARK: - Data
struct LockedWEntry: TimelineEntry {
    
    let date: Date
    let wData: WidgetDataCoordinator.WidgetData
    let relevance: TimelineEntryRelevance
    var url:URL {
        URL(string: "tb://" + wData.id) ?? URL(string: "tb://")!
    }
}

struct LockedWProvider: IntentTimelineProvider {
        
    func placeholder(in context: Context) -> LockedWEntry {
        LockedWEntry(date: Date(), wData: Coordinator.dummyWData, relevance: TimelineEntryRelevance(score: 0))
    }
    
    func getSnapshot(for configuration:Intent, in context: Context, completion: @escaping (LockedWEntry) -> ()) {
        let entry:LockedWEntry
        
        let wData = Coordinator.widgetData(from: configuration.timeBubble?.identifier)
        var relevance:TimelineEntryRelevance {
            TimelineEntryRelevance(score: wData.state == .running ? 1.0 : 0.1)
        }
        
        entry = LockedWEntry(date: Date(), wData: wData, relevance: relevance)
        completion(entry)
    }

    func getTimeline(for configuration:Intent, in context: Context, completion: @escaping (Timeline<LockedWEntry>) -> ()) {
        
        var entries = [LockedWEntry]()
        
        let wData = Coordinator.widgetData(from: configuration.timeBubble?.identifier)
        
        let relevance = TimelineEntryRelevance(score: wData.state == .running ? 1.0 : 0.1)
        let firstEntry = LockedWEntry(date: Date(), wData: wData, relevance:relevance)
        entries.append(firstEntry)
        
        if wData.isTimer, wData.state == .running {
            let delta =
                wData.currentClock - Date().timeIntervalSince(wData.lastStartdate!)
            let endDate = Date().addingTimeInterval(delta)
            
            let zeroTimerData = Coordinator.zeroTimerData(from: wData)
            
            let relevance = TimelineEntryRelevance(score: 0.1)
            let zeroTimeEntry = LockedWEntry(date: endDate, wData: zeroTimerData, relevance: relevance)
            
            entries.append(zeroTimeEntry)
        }
        
        let timeline = Timeline(entries: entries, policy: .never)
        
        completion(timeline)
    }
    
    //helper
    private func computeZeroTimerEndDate(_ components:DateComponents) -> Date {
        let date = Calendar.current.date(byAdding: components, to: Date())
        return date!
    }
}

// MARK: - Preview
struct SquareWidget_Previews: PreviewProvider {
    static func dummyData() -> WidgetDataCoordinator.WidgetData {
        WidgetDataCoordinator.WidgetData(id: String.empty,
                                         color: "Charcoal",
                                         stickyNote: "Pula",
                                         state: .brandNew,
                                         isCalendarEnabled: true,
                                         isTimer: false,
                                         referenceClock: 0.0,
                                         currentClock: 0.0,
                                         lastStartdate: nil,
                                         sessionCount: 0)
    }
    static var previews: some View {
        LockedWidgetEntryView(entry: LockedWEntry(date: Date(), wData:SquareWidget_Previews.dummyData(), relevance: TimelineEntryRelevance(score: 0)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
