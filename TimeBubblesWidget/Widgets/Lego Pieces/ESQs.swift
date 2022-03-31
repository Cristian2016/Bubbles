//
//  Shapeshifters.swift
//  TimeBubblesWidgetExtension
//
//  Created by Cristian Lapusan on 08.07.2021.
//

import SwiftUI
import WidgetKit

struct ESQs: View {
    //properties
    let kind:Squircle.Kind
    let colors:Colors
    
    let /* circle */offsets = [
        ESQ.Position.topLeft:CGPoint(x: -40, y: -40),
        .middleRight:CGPoint(x: 50, y: 10),
        .bottomLeft:CGPoint(x: -50, y: 45)]
    
    func offset(for position:ESQ.Position) -> CGPoint {
        guard kind != .square else { return .zero }
        return offsets[position] ?? .zero
    }
    
    let /* circle */scales = [
        ESQ.Position.topLeft:CGFloat(0.9),
        .middleRight:0.75,
        .bottomLeft:1.0
    ]
    
    func scale(for position:ESQ.Position) -> CGFloat {
        guard kind != .square else { return 1.0 }
        return scales[position] ?? 1.0
    }
    
    //main part
    var body: some View {
        ZStack {
            ESQ(kind, .bottomLeft)
                .modifier(ShapeModifier(colors.intense,
                                        hasShadow: false,
                                        offset: offset(for: .bottomLeft),
                                        scale: scale(for: .bottomLeft)))
            ESQ(kind, .middleRight)
                .modifier(ShapeModifier(colors.medium,
                                        hasShadow: true,
                                        offset: offset(for: .middleRight),
                                        scale: scale(for: .middleRight)))
            ESQ(kind, .topLeft)
                .modifier(ShapeModifier(colors.light,
                                        hasShadow: true,
                                        offset: offset(for: .topLeft),
                                        scale: scale(for: .topLeft)))
        }
    }
    
    //init
    init(_ kind:Squircle.Kind, _ colors:Colors) {
        self.kind = kind
        self.colors = colors
    }
}

struct ShapeModifier:ViewModifier {
    let color:Color
    let hasShadow:Bool
    let offset:CGPoint?
    let scale:CGFloat
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: .black.opacity(hasShadow ? 0.3 : 0.0), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
            .scaleEffect(scale)
    }
    
    init(_ color:Color,
         hasShadow:Bool = false,
         offset:CGPoint?,
         scale:CGFloat) {
        
        self.color = color
        self.hasShadow = hasShadow
        self.offset = offset
        self.scale = scale
    }
}

///Encapsulated Squircle. A square or circle that has on all sides a spacer, so that it can be pushed left right and so on
struct ESQ:View {
    //properties and init
    let kind:Squircle.Kind
    let position:Position
    
    let ratio = CGFloat(0.7)
    let topRatio = CGFloat(1.16)
    var bottomRatio:CGFloat { 1 - topRatio }
    
    init(_ kind:Squircle.Kind, _ position:Position) {
        self.kind = kind
        self.position = position
    }
    
    //other properties
    var shadow:Bool {
        (position == .bottomLeft) ? false : true
    }
    
    func margins(_ spacerWidth:CGFloat) -> Margins {
        switch kind {
        case .circle: return Margins.zero
        default:
            switch position {
            case .topLeft:
                return Margins(top: 0, bottom: spacerWidth, left: 0, right: spacerWidth)
            case .bottomLeft:
                return Margins(top: spacerWidth, bottom: 0, left: 0, right: spacerWidth)
            case .middleRight:
                return Margins(top: spacerWidth * topRatio, bottom: spacerWidth * bottomRatio, left: spacerWidth, right: 0)
            }
        }
    }
    
    //main shit
    var body: some View {
        GeometryReader {
            let height = $0.size.height
            let spacerWidth = 0.3 * height
            let m = margins(spacerWidth)
            
            VStack {
                Spacer(minLength:m.top)
                HStack {
                    Spacer(minLength:m.left)
                    Squircle(kind)
                    Spacer(minLength:m.right)
                }
                Spacer(minLength:m.bottom)
            }
        }
    }
    
    enum Position {
        case topLeft //light
        case middleRight //medium
        case bottomLeft //intense
    }
}

struct Margins {
    let top:CGFloat
    let bottom:CGFloat
    let left:CGFloat
    let right:CGFloat
    
    static let zero = Margins(top: 0, bottom: 0, left: 0, right: 0)
}

struct Squircle:View {
    let kind:Kind
    
    @ViewBuilder
    var body: some View {
        switch kind {
        case .circle: Circle()
        case .square: ContainerRelativeShape()
        }
    }

    //enum
    enum Kind {
        case circle
        case square
    }
    
    init(_ kind:Kind) {
        self.kind = kind
    }
}

// MARK: - preview
struct Shapeshifters_Previews: PreviewProvider {
    static var previews: some View {
        ESQs(.square, Colors(.red, .yellow, .green))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
