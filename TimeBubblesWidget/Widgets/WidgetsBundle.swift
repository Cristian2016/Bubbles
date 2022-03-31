import SwiftUI
import WidgetKit

@main
struct Widgets:WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        FreeWidget() /* 1st kind */
        LockedWidget() /* 2nd kind */
    }
}

// MARK: - Widgets
//Widget
struct LockedWidget: Widget {
    let kind: String = "SquareWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind,
                            intent: DynamicTimeBubbleSelectionIntent.self,
                            provider: LockedWProvider()) { LockedWidgetEntryView(entry: $0) }
            .configurationDisplayName("Quick Access")
            .description("To Any Time Bubble.")
            .supportedFamilies([.systemSmall]) //small widgets only
    }
}

struct FreeWidget:Widget {
    let kind = "RoundWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: FreeWProvider()) {entry in
            FreeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tracks Most Recently Active")
        .description("Time Bubble.")
        .supportedFamilies([.systemSmall])
    }
}

//EntryView
struct LockedWidgetEntryView : View {
    var entry: LockedWProvider.Entry
    
    var body: some View {
        LockedWidgetView(wData: entry.wData)
            //⚠️ does not work property if I put TimeBubbleWidget inside a Link
            .widgetURL(entry.url)
    }
}

struct FreeWidgetEntryView:View {
    let entry:FreeWEntry
    
    var body: some View {
        FreeWidgetView(wData: entry.wData)
            .widgetURL(entry.url)
    }
}

//WidgetView

//Main Widget
struct LockedWidgetView:View {
    static let name = "group.com.TimeBubbles.widget"
    let wData:WidgetDataCoordinator.WidgetData
    let gradient = Gradient(colors: [.white,.white, .white,Color(#colorLiteral(red: 0.7293493748, green: 0.7294532657, blue: 0.7293166518, alpha: 1))])
    
    var body: some View {
        switch wData {
        case WidgetDataCoordinator.dummyWData: LockedWidgetPlaceholderView()
        default: LockedWidgetRegularView(wData: wData)
        }
    }
}

struct FreeWidgetView: View {
    let wData:WidgetDataCoordinator.WidgetData
    
    var body: some View {
        if wData == WidgetDataCoordinator.dummyWData { FreeWidgetPlaceholderView() }
        else { FreeWidgetRegularView(wData: wData) }
    }
}
