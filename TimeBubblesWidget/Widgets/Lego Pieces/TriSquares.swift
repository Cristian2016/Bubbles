import SwiftUI
import WidgetKit

struct TriSquares: View {
    let colors:Colors
    let /* widget */ height:CGFloat
    let /* spacerToWidgetLengths _ / ___ */ratio = CGFloat(0.32)
    
    var body: some View {
        ZStack {
            VStack {//intense
                Spacr
                HStack {
                    ContainerRelativeShape()
                        .foregroundColor(colors.intense)
                    Spacer(minLength: height * ratio)
                }
            }
            VStack {//medium
                HStack {
                    Spacer(minLength: height * ratio)
                    ZStack {
                        VStack {
                            Spacer()
                            ContainerRelativeShape()
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
                                .padding(0.2)
                        }
                        ContainerRelativeShape()
                            .foregroundColor(colors.medium)
                    }
                    .offset(x: 0, y: 0.182 * height)
                }
                Spacr
            }
            VStack {//light
                HStack {
                    ContainerRelativeShape()
                        .foregroundColor(colors.light)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
                    Spacer(minLength: height * ratio)
                }
                Spacr
                Spacer(minLength: 4)
            }
        }
    }
    
    var Spacr: some View {
        Spacer(minLength: height * ratio)
    }
}

struct TriSquares_Previews: PreviewProvider {
    static var previews: some View {
        TriSquares(colors: Colors(.red, .blue, .green), height: 155)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
