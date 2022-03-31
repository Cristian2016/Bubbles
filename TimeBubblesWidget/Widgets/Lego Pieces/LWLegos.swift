//
//  SmallWidgetView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 15.06.2021.
//

import SwiftUI
import WidgetKit

// MARK: - Regular view
struct LockedWidgetRegularView:View, ColorIdentifiable {
    var colorString: String { wData.color }
    
    //stuff
    let wData:WidgetDataCoordinator.WidgetData
    var isZeroTimer:Bool { wData.state == .zeroTimer }
    var showPauseSticker:Bool {
        [WidgetDataCoordinator.State.brandNew, .paused].contains(wData.state)
    }
    var showDoneSticker:Bool { wData.state == .zeroTimer }
    
    //body
    var body: some View {
        GeometryReader {
            let colors = colors()
            let height = $0.size.height
            let stickyViewTextOffsetY = wData.isCalendarEnabled ? -height * 0.41 : -height * 0.41 + 2
            
            ZStack {
                TriSquares(colors: colors, height: height)
//                ESQs(.square, colors)
                
                //digits
                DigitsBackground(color: colors.intense, isCalendarEnabled: wData.isCalendarEnabled)
                DigitsView(wData:wData)
                
                //the rest
                if showPauseSticker { PauseSticker() }
                if showDoneSticker { DoneSticker() }
                SessionCountView(sessionCount: wData.sessionCount)
                
                StickyTextView(wData.stickyNote)
                    .offset(x: -height * 0.16, y: stickyViewTextOffsetY)
            }
        }
    }
}

// MARK: - Lego Pieces
struct DigitsBackground:View {
    //stuff
    let color:Color
    let isCalendarEnabled:Bool
    
    let backgroundHeight = CGFloat(67)
    var calendarLabelHeight:CGFloat { backgroundHeight + 5 }
    
    let calendarLabelWidth = CGFloat(70.0)
    let backgroundRadius = CGFloat(14)
    let calendarLabelRadius = CGFloat(8)
    var calendarLabelOffsetY:CGFloat {
       backgroundHeight - calendarLabelHeight
    }
    
    //body
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: calendarLabelRadius)
                .frame(width: calendarLabelWidth, height: calendarLabelHeight)
                .offset(x: -24, y: calendarLabelOffsetY)
                .foregroundColor(isCalendarEnabled ? Color("Calendar") : .clear)
            RoundedRectangle(cornerRadius: backgroundRadius)
                .frame(height: backgroundHeight)
                .foregroundColor(color)
            
//            LinearGradient(gradient: Gradient(colors: [color, color,color,color,color,color,color,color, .white]), startPoint: .bottom, endPoint: .top)
//                .clipShape(RoundedRectangle(cornerRadius: 14))
//                .frame(height: 70)
        }
    }
}

struct StickyTextView:View {
    let stickyNote:String
    init(_ stickyNote:String) {
        self.stickyNote = stickyNote
    }
    
    var body: some View {
        Text(stickyNote)
            .fontWeight(.medium)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .foregroundColor(.white)
            .font(.system(.headline, design: .rounded))
            .padding(EdgeInsets(top: 6, leading: 0, bottom: -7, trailing: 0))
    }
}

struct PauseSticker:View {
    var body: some View {
        HStack {
            Spacer()
            Spacer()
            Image("Pause")
                .resizable()
            Spacer()
            Spacer()
        }
        .foregroundColor(.white.opacity(0.7))
        .frame(minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight:2, maxHeight: 2)
    }
}

struct DoneSticker:View {
    var body: some View {
        HStack {
            Spacer()
            Text("✗")
                .fontWeight(.medium)
                .font(.title2)
                .foregroundColor(.white)
                .offset(x: 0, y: 6)
        }
        .padding(10)
    }
}

struct SessionCountView:View {
    let sessionCount:Int
    let showSession:Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                if sessionCount != 0 {
                    HStack (spacing: 0) {
                        Text(String(sessionCount > 0 ? String(sessionCount) : String.empty))
                            .fontWeight(.semibold)
                            .font(.title)
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.4)
                            .frame(width: 24, height: 24, alignment: .center)

                        if showSession {
                            Text("Sess.")
                                .fontWeight(.medium)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .offset(x: 0, y: 12)
                        }
                    }
                    Spacer()
                }
            }
            .padding(10)
        }
    }
}

struct DigitsView:View {
    let wData:WidgetDataCoordinator.WidgetData
    var isDummyData:Bool {
        wData == WidgetDataCoordinator.dummyWData ? true : false
    }
    
    private func date() -> Date {
        guard wData.state == .running else { return Date() }
        
        //time interval between last start and now
        let elapsedTimeSinceLastStart:TimeInterval
        if let lastStart = wData.lastStartdate {
            elapsedTimeSinceLastStart = Date().timeIntervalSince(lastStart)
        } else {
            elapsedTimeSinceLastStart = 0.0
        }
        
        let totalElapsed:TimeInterval
        
        if wData.isTimer {//timer
            totalElapsed = (wData.currentClock - elapsedTimeSinceLastStart)
        } else {//stopwatch
            totalElapsed = wData.currentClock + elapsedTimeSinceLastStart
        }
        
        let timerCorrection = TimeInterval(1)
        let start = wData.isTimer ?
            totalElapsed + timerCorrection : -totalElapsed
        
        return Date().addingTimeInterval(start)
    }
    
    ///time to display when timeBubble is not running
    private func text() -> String {
        if [WidgetDataCoordinator.State.brandNew, .paused].contains(wData.state) {
            let timeComponents = wData.currentClock.time()
            let hr = timeComponents.hr
            let min = timeComponents.min
            let sec = Int(timeComponents.sec.rounded(.toNearestOrEven))
            
            let condition = timeComponents == (hr: 0, min: 0, sec: 0)
            return condition ? "0:00" : "\(hr):\(min):\(sec)"
        }
        if wData.state == .zeroTimer {
            return "0:00"
        }
        return "fix text()"
    }
    
    var body: some View {
        VStack {
            switch wData.state {
            case .running:
                if isDummyData { DummyDataText() }
                else { Text(date(), style: .timer) /* running */ }
            default: Text(text())
            }
        }
        .modifier(CustomModifier())
    }
}

struct DummyDataText:View {
    var body: some View {
        Text("・Tap & hold\n・Edit Widget\n・Choose")
            .foregroundColor(.black)
            .background(ContainerRelativeShape()
                            .padding(EdgeInsets(top: -14,
                                                leading: -8,
                                                bottom: -14,
                                                trailing: -8))
                            .foregroundColor(.white.opacity(0.6)))
            .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
            .lineLimit(3)
            .padding(16)
    }
}

// MARK: - Helper
struct CustomModifier:ViewModifier {
    func body(content: Content) -> some View {
        content
            .truncationMode(.head)
            .font(.title)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .allowsTightening(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            .padding(2)
            .scaleEffect(1.05)
            .foregroundColor(.white)
    }
}

// MARK: - preview
struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LockedWidgetView(wData: WidgetDataCoordinator.dummyWData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
