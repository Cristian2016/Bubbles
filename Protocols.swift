//
//  Protocols.swift
//  TimeBubblesWidgetExtension
//
//  Created by Cristian Lapusan on 04.07.2021.
//

import Foundation
import UIKit
import SwiftUI

protocol ColorIdentifiable {
    var colorString:String { get }
}

extension ColorIdentifiable {
    func colors() -> Colors {
        if let result = TricolorProvider.tricolors(forName: colorString).first {
            return Colors(Color(result.intense), Color(result.medium), Color(result.light))
        }
        return Colors(.red, .black, .purple)
    }
}

struct Colors {
    init(_ intense:Color, _ medium:Color, _ light:Color) {
        self.intense = intense
        self.medium = medium
        self.light = light
    }
    let intense:Color
    let medium:Color
    let light:Color
}
