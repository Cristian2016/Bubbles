import UIKit
import WidgetKit

/*colors are stored in a plist file and this class makes them available globally since most VCs and views, such as Circle in Palette, use colors*/

class TricolorProvider {
    
    struct RGB:Decodable {
        let red:Int
        let green:Int
        let blue:Int
    }

    struct RGBTricolor:Decodable {
        let name:String
        let light:RGB
        let medium:RGB
        let intense:RGB
    }

    public struct Tricolor {
        let name:String
        let light:UIColor
        let medium:UIColor
        let intense:UIColor
        
        fileprivate init(name: String, light: UIColor, medium: UIColor, intense: UIColor) {
            self.name = name
            self.light = light
            self.medium = medium
            self.intense = intense
        }
    }
    
    private(set) static var tricolors:[Tricolor] = {
        return fetchTricolors()
    }()
    
    private static func fetchTricolors() -> [Tricolor] {
        guard
            let tricolorsURL = Bundle.main.url(forResource: "Tricolors", withExtension: "plist"),
            let tricolorsData = try? Data(contentsOf: tricolorsURL)
            else { return [] }
        
        let plistDecoder = PropertyListDecoder()
        guard let rgbTricolors = try? plistDecoder.decode([RGBTricolor].self, from: tricolorsData)
            else { return [] }
        
        var tricolors = [Tricolor]()
        for rgbTricolor in rgbTricolors {
            let lightColor = UIColor.rgb(rgbTricolor.light.red, rgbTricolor.light.green, rgbTricolor.light.blue)
            let mediumColor = UIColor.rgb(rgbTricolor.medium.red, rgbTricolor.medium.green, rgbTricolor.medium.blue)
            let intenseColor = UIColor.rgb(rgbTricolor.intense.red, rgbTricolor.intense.green, rgbTricolor.intense.blue)
            
            let tricolor = Tricolor(name: rgbTricolor.name, light: lightColor, medium: mediumColor, intense: intenseColor)
            tricolors.append(tricolor)
        }
        return tricolors
    }
    
    private init(){}
    
    static func tricolors(forName name:String) -> [Tricolor] {
        var tricolors = [Tricolor]()
        TricolorProvider.tricolors.forEach {if $0.name == name {tricolors.append($0)}}
        return tricolors
    }
    
    static let colorEmojis = ["lemon":"🟨",
                              "red":"🟥",
                              "ultramarine":"🟦",
                              "green":"🟩",
                              "orange":"🟧",
                              "purple":"🟪",
                              "charcoal":"⬛️",
                              "silver":"⬜️",
                              "chocolate":"🟫"]
    
    static func colorEmoji(_ colorName:String?) -> String {
        guard let colorName = colorName else { return String.empty }
        return colorEmojis[colorName.lowercased()] ?? String.empty
    }
}
