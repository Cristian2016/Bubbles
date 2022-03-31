import SwiftUI
import WidgetKit

struct FreeWidgetRegularView: View, ColorIdentifiable {
    var colorString: String { wData.color }
    
    //stuff
    func stickyColor() -> Color? {
        if wData.isCalendarEnabled {
            return Color("Calendar")
        } else {
            if !wData.stickyNote.isEmpty {
                return Color("Sticky")
            }
        }
        return nil
    }
    let wData:WidgetDataCoordinator.WidgetData
    
    //body
    var body: some View {
        GeometryReader {
            let colors = colors()
            let height = $0.size.height
            let stickyViewTextOffsetY = wData.isCalendarEnabled ? -height * 0.41 : -height * 0.41 + 2
            
            ZStack {
                TriCircles(colors)
                if wData.isCalendarEnabled {
                    Ellipse()
                        .foregroundColor(stickyColor())
                        .frame(width: 80, height: 40)
                        .rotationEffect(Angle(degrees: -10))
                        .offset(x: -30, y: -20)
                }
                Ellipse()
                    .frame(height: 70, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(colors.intense)
                
                DigitsView(wData:wData)
                if [WidgetDataCoordinator.State.brandNew, .paused].contains(wData.state) {
                    PauseSticker()
                }
                if wData.state == .zeroTimer { DoneSticker() }
                SessionCountView(sessionCount: wData.sessionCount)
                StickyTextView(wData.stickyNote)
                    .offset(x: -height * 0.16, y: stickyViewTextOffsetY)
            }
        }
    }
}

// MARK: - Lego parts
struct TriCircles:View {
    typealias Modifier = CirclesModifier
    let colors:Colors
    init(_ colors:Colors) {
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            Circle()
                .modifier(Modifier(colors.intense, (x: -50, y: 45), 1.0))
            Circle()
                .shadow(color: .black.opacity(0.3), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
                .modifier(Modifier(colors.medium, (x: 50, y: 10), 0.75))
            Circle()
                .modifier(Modifier(colors.light, (x: -40, y: -40), 0.90))
                .shadow(color: .black.opacity(0.3), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
        }
    }
}

struct CirclesModifier:ViewModifier {
    let color:Color
    let offsets:(x:CGFloat, y:CGFloat)
    let scale:CGFloat
    
    init(_ color:Color,
         _ offsets:(x:CGFloat, y:CGFloat),
         _ scale:CGFloat) {
        
        self.color = color
        self.offsets = offsets
        self.scale = scale
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .offset(x: offsets.x, y: offsets.y)
            .scaleEffect(scale)
    }
}

// MARK: - Preview
struct FreeWidgetRegularView_Previews: PreviewProvider {
    static var previews: some View {
        FreeWidgetRegularView(wData: WidgetDataCoordinator.dummyWData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
