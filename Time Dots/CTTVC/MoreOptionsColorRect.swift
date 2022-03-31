//
//  MoreOptionsColorCircle.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 08.12.2021.
//

import UIKit

class MoreOptionsColorRect:UIButton {
    @IBInspectable
    var fillColor:UIColor = UIColor.clear
    
    @IBInspectable
    var radius:CGFloat = 4
    
    override func draw(_ rect: CGRect) {
        let rectangle = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        fillColor.setFill()
        rectangle.fill()
    }
}
