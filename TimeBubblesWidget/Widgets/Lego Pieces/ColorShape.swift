//
//  ColorTimeComponentView.swift
//  TimeBubblesWidgetExtension
//
//  Created by Cristian Lapusan on 17.06.2021.
//

import SwiftUI
import WidgetKit

struct ColorSquare: View {
    let position:Position
    let color:Color
    var stickyNote:String? = nil
    var stickyNoteColor:Color? = nil
    
    var body: some View {
        HStack {
            if position == .trailingMiddle {
                Spacer(minLength: 50)
            }
            VStack {
                if position == .bottomLeft {
                    Spacer(minLength: 50)
                }
                ZStack {
                    ContainerRelativeShape()
                        .foregroundColor(color)
                        .aspectRatio(1.0, contentMode: .fit)
                    ZStack {
                        VStack {
                            if let stickyNote = stickyNote, !stickyNote.isEmpty {
                                StickyTextView(stickyNote)
                            } else {
                                Spacer(minLength: 30)
                            }
                           
                            HStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 8)
                                Spacer()
                            }
                            .foregroundColor(stickyNoteColor ?? .clear)
                        }
                    }
                }
                if position == .topLeft {
                    Spacer(minLength: 50)
                }
            }
            if [Position.bottomLeft, .topLeft].contains(position) {
                Spacer(minLength: 50)
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
    
    // MARK: -
    enum Position:CustomStringConvertible {
        var description: String {
            switch self {
            case .trailingMiddle: return "trailingMiddle"
            case .topLeft: return "topLeft"
            case .bottomLeft: return "bottomLeft"
            }
        }
        
        case trailingMiddle
        case topLeft
        case bottomLeft
    }
}

struct ColorTimeComponentView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSquare(position: .topLeft, color: Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)), stickyNote: "Outdoors", stickyNoteColor: .red)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
