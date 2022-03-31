//
//  File.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Fri  26.02.2021.
//

import UIKit

class Marble: UIView {
    override func draw(_ rect: CGRect) {
        let marbleDiameter = UI.Constants.marbelDiameter * rect.height
        let origin = CGPoint(x: (bounds.midX - marbleDiameter/2), y: UI.Constants.marbelDistanceFromTopMargin/2)
        let position = CGRect(origin: origin, size: CGSize(width: marbleDiameter, height: marbleDiameter))
        let path = UIBezierPath(ovalIn: position)
        UIColor.white.setFill()
        path.fill()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
