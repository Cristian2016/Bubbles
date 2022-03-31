import SwiftUI
import WidgetKit

//Locked Placeholder
struct LockedWidgetPlaceholderView:View {
    
    let gradient = Gradient(colors: [.white,.white, .white, .black])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Spacer(minLength: geometry.size.height * 0.65)
                    LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
                }
                ZStack {
                    ColorSquare(position: .bottomLeft, color: Color(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                    ColorSquare(position: .topLeft, color: Color(#colorLiteral(red: 0, green: 0.7838205695, blue: 1, alpha: 1)))
                    ColorSquare(position: .trailingMiddle, color: Color(#colorLiteral(red: 0.9974866509, green: 0.1490378678, blue: 0.001191380434, alpha: 1)))
                        .offset(y: 10)
                }
                .shadow(color: .black.opacity(0.20), radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/, x: 1, y: 1)
                ExplainingText(color: Color(#colorLiteral(red: 0.003921750002, green: 0.7798067331, blue: 1, alpha: 1)), text: "① Tap & hold\n② Edit Widget")
            }
        }
    }
}

struct ExplainingText:View {
    let color:Color
    var text:String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .padding(EdgeInsets(top: 40, leading: 0, bottom: 40, trailing: 0))
                .foregroundColor(color)
            
            Text(text)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
                .foregroundColor(.white)
                .font(.system(.title3, design: .rounded))
                .padding(8)
        }
    }
}

//Free Placeholder
struct FreeWidgetPlaceholderView:View {
    
    let gradient = Gradient(colors: [.white,.white, .white, .black])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Spacer(minLength: geometry.size.height * 0.40)
                    LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
                }
                ZStack {
                    
                    Circle()
                        .foregroundColor(Color(#colorLiteral(red: 0.9881522059, green: 0.9882902503, blue: 0.9881088138, alpha: 1))) //light
                        .frame(width: geometry.size.width * 0.85)
                        .offset(x: -30, y: 3)
                        .shadow(color: .gray.opacity(0.7), radius: 4, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
                    ZStack (alignment:.center) {
                        Circle()
                            .foregroundColor(Color(#colorLiteral(red: 0.1060828194, green: 0.8074872494, blue: 1, alpha: 1))) //medium
                            .frame(width: geometry.size.width * 0.88)
                            .offset(x: 40, y:-40)
                            .shadow(color: .black.opacity(0.20), radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/, x: 1, y: 1)
                    }
                    ZStack {
                        Circle()
                            .foregroundColor(Color(#colorLiteral(red: 0.9890579581, green: 0.1446989775, blue: 0.006807035767, alpha: 1))) //intense
                            .frame(width: geometry.size.width * 0.70)
                            .offset(x: -2)
                        Circle()
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width * 0.25)
                            .offset(x: -10.0, y: -10.0)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct TriRect_Previews: PreviewProvider {
    static var previews: some View {
        FreeWidgetPlaceholderView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
