//
//  PairNumberBackground.swift
//
//  Created by Cristian Lăpușan on Fri  9.04.2021.
//

import UIKit

class PairNumberBackground: UIView {
    var color:UIColor? {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        (color ?? .systemGray2).setFill()
        path.fill()
    }
}
