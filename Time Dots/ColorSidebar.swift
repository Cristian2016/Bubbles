//
//  ColorSidebar.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Mon  29.03.2021.
//

import UIKit

class ColorSidebar: UIView {
    
    var color:UIColor? {didSet{
        setNeedsDisplay()
    }}
    
    override func draw(_ rect: CGRect) {
        let rectangle = UIBezierPath(rect: rect)
        color?.setFill()
        rectangle.fill()
    }
}
