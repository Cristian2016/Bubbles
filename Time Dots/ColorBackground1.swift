//
//  GrayBackgroundView.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Sun  14.03.2021.
//

import UIKit

class ColorBackground1:  UIView {
    
    func set(cornerRadius:CGFloat = 0.0, fillColor:UIColor) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        setNeedsDisplay()
    }
    
    private(set) lazy var fillColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
    private lazy var cornerRadius:CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        fillColor.setFill()
        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        roundedRect.fill()
    }
}

class ColorAccolade:  UIView {
    
    func set(cornerRadius:CGFloat = 9, strokeColor:UIColor) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
        
        let whiteCover = UIView(frame: CGRect(origin: .zero, size: CGSize(width: bounds.size.width * 2,
                                                                         height: bounds.size.height)))
        whiteCover.backgroundColor = .systemBackground
        addSubview(whiteCover)
        whiteCover.transform = CGAffineTransform(translationX: 40, y: 0)
        
        setNeedsDisplay()
    }
    
    private lazy var height = frame.size.height
    private(set) var strokeColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1).withAlphaComponent(0.2)
    private var cornerRadius:CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        
        strokeColor.setStroke()
        let roundedRect = UIBezierPath(roundedRect: rect.insetBy(dx: 14, dy: 14), cornerRadius: cornerRadius)
        roundedRect.lineWidth = 3
        roundedRect.lineCapStyle = .round
        roundedRect.stroke()
    }
}
