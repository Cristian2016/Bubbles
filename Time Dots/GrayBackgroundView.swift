//
//  GrayBackgroundView.swift
//  Time Dots
//
//  Created by Cristian Lăpușan on Sun  14.03.2021.
//

import UIKit

@IBDesignable
class ColorBackground:  UIView {
    
    func set(height:CGFloat, cornerRadius:CGFloat, fillColor:UIColor) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        
        setNeedsDisplay()
    }
    
    private lazy var height = frame.size.height
    private lazy var fillColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
    private lazy var cornerRadius:CGFloat = 15
    
    override func draw(_ rect: CGRect) {
        
        fillColor.setFill()
        
        let frame = CGRect(origin: .zero, size: CGSize(width: rect.size.width, height: height))
        let roundedRect = UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius)
        roundedRect.fill()
    }
}
