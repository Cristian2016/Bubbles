//
//  RoundWidget.swift
//  TimeBubblesWidgetExtension
//
//  Created by Cristian Lapusan on 03.07.2021.
//

import SwiftUI
import WidgetKit

// MARK: - Data part
struct FreeWEntry:TimelineEntry {
    let date:Date
    let wData:WidgetDataCoordinator.WidgetData
    var url:URL {
        URL(string: "tb://" + wData.id) ?? URL(string: "tb://")!
    }
}

struct FreeWProvider:TimelineProvider {
    
    func placeholder(in context: Context) -> FreeWEntry {
        FreeWEntry(date: Date(), wData: WidgetDataCoordinator.dummyWData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FreeWEntry) -> Void) {
        let entry = FreeWEntry(date: Date(), wData: WidgetDataCoordinator.dummyWData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FreeWEntry>) -> Void) {
        var entries = [FreeWEntry]()
        
        /*
         the widget reads from the sharedFile timeBubble.ID it should display. CTTVC writes to the sharedFile
         */
        
        let wData =
            WidgetDataCoordinator.widgetData(from: getIDFromSharedFile())
        
        let entry = FreeWEntry(date: Date(), wData: wData)
        entries.append(entry)
        
        if wData.isTimer, wData.state == .running {
            let delta =
                wData.currentClock - Date().timeIntervalSince(wData.lastStartdate!)
            let endDate = Date().addingTimeInterval(delta)
            
            let zeroTimerData = WidgetDataCoordinator.zeroTimerData(from: wData)
            let zeroTimeEntry = FreeWEntry(date: endDate, wData: zeroTimerData)
            
            entries.append(zeroTimeEntry)
        }
        
        let timeline = Timeline<FreeWEntry>(entries: entries, policy: .never)
        completion(timeline)
    }
    
    //helper
    private func getIDFromSharedFile() -> String? {
        let file = FileManager.sharedFolder.appendingPathComponent("latestStartedTimeBubbleID")
        if FileManager.default.fileExists(atPath: file.path) {
            if let content = try? String(contentsOfFile: file.path, encoding: .utf8) {
                return content
            }
            else { return nil }
        }
        else { return nil }
    }
}

// MARK: - Preview
struct RoundWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        FreeWidgetView(wData: WidgetDataCoordinator.dummyWData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
