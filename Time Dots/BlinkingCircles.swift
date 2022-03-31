//
//  BlinkingCircles.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 24.05.2021.
//

import UIKit

class BlinkingCircles: UIView {
    @IBOutlet var container: UIView!
    
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var circle0: BlinkingCircle!
    @IBOutlet weak var circle1: BlinkingCircle!
    @IBOutlet weak var circle2: BlinkingCircle!
    
    var fillColor:UIColor? {didSet{
        circle0.fillColor = fillColor ?? .white
        circle1.fillColor = fillColor ?? .white
        circle2.fillColor = fillColor ?? .white
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let name = "BlinkingCircles"
        let nibView =
            Bundle.main.loadNibNamed(name, owner: self, options: nil)?.first as? UIView
        
        //set container to nibView
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}

class BlinkingCircle: UIView {
    
    var fillColor = UIColor.systemGray4 {didSet{ setNeedsDisplay() }}
    override func draw(_ rect: CGRect) {
        let circle = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        circle.fill()
    }
}
