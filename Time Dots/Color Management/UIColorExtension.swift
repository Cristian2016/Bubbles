//
//  UIColorExtension.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 13.02.2022.
//

import UIKit

enum ColorIntensity:String {
    case light = "Light"
    case medium = "Medium"
    case intense = "Intense"
    case text = "Text"
}

enum ColorName:String {
    case mint = "Mint"
    case slateBlue = "Slate Blue"
    case sourCherry = "Sour Cherry"
    
    case silver = "Silver"
    case ultramarine = "Ultramarine"
    case lemon = "Lemon"
    
    case red = "Red"
    case sky = "Sky"
    case bubbleGum = "Bubble Gum"
    
    case green = "Green"
    case charcoal = "Charcoal"
    case magenta = "Magenta"
    
    case purple = "Purple"
    case orange = "Orange"
    case chocolate = "Chocolate"
    
    case aqua = "Aqua"
    case byzantium = "Byzantium"
    case rose = "Rose"
}

typealias Shade = (light:UIColor, medium:UIColor, intense:UIColor)

extension UIColor {
    //⚠️ keypaths do NOT work with static properties
    
    static let _mint = UIColor(named: ColorName.mint.rawValue)!
    static let _slateBlue = UIColor(named: ColorName.slateBlue.rawValue)!
    static let _sourCherry = UIColor(named: ColorName.sourCherry.rawValue)!
    
    static let _silver = UIColor(named: ColorName.silver.rawValue)!
    static let _ultramarine = UIColor(named: ColorName.ultramarine.rawValue)!
    static let _lemon = UIColor(named: ColorName.lemon.rawValue)!
    
    static let _red = UIColor(named: ColorName.red.rawValue)!
    static let _sky = UIColor(named: ColorName.sky.rawValue)!
    static let _bubbleGum = UIColor(named: ColorName.bubbleGum.rawValue)!
    
    static let _green = UIColor(named: ColorName.green.rawValue)!
    static let _charcoal = UIColor(named: ColorName.charcoal.rawValue)!
    static let _magenta = UIColor(named: ColorName.magenta.rawValue)!
    
    static let _purple = UIColor(named: ColorName.purple.rawValue)!
    static let _orange = UIColor(named: ColorName.orange.rawValue)!
    static let _chocolate = UIColor(named: ColorName.chocolate.rawValue)!
    
    static let _aqua = UIColor(named: ColorName.aqua.rawValue)!
    static let _byzantium = UIColor(named: ColorName.byzantium.rawValue)!
    static let _rose = UIColor(named: ColorName.rose.rawValue)!
    
    static func color(_ name:String, _ intensity:ColorIntensity = .intense) -> UIColor {
        guard let colorName = ColorName(rawValue: name) else { return .cyan }
        
        switch colorName {
        case .mint: return UIColor._mint
        case .slateBlue: return UIColor._slateBlue
        case .sourCherry: return UIColor._sourCherry
            
        case .silver: return UIColor._silver
        case .ultramarine: return UIColor._ultramarine
        case .lemon: return UIColor._lemon
            
        case .red: return UIColor._red
        case .sky: return UIColor._sky
        case .bubbleGum: return UIColor._bubbleGum
            
        case .green: return UIColor._green
        case .charcoal: return UIColor._charcoal
        case .magenta: return UIColor._magenta
            
        case .purple: return UIColor._purple
        case .orange: return UIColor._orange
        case .chocolate: return UIColor._chocolate
            
        case .aqua: return UIColor._aqua
        case .byzantium: return UIColor._byzantium
        case .rose: return UIColor._rose
        }
    }
}
