//
//  AnimationsButton.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 21.04.2021.
//

import UIKit

//IMG_49BF4642B74C-1.jpeg
class AnimationsButton: UIButton {
    
    var strokeColor:UIColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1) { didSet{ setNeedsDisplay() }}
    
    @IBInspectable var lineWidth:CGFloat = 8
    
    override func draw(_ rect: CGRect) {
        let key = UserDefaults.Key.isAnimationOnAppearEnabled
        if let value = UserDefaults.standard.value(forKey: key) as? Bool {
            strokeColor = !value ? #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) : .red
        }
        let circle = UIBezierPath(ovalIn: rect.insetBy(dx: lineWidth/2, dy: lineWidth/2))
        
        strokeColor.setStroke()
        circle.lineWidth = lineWidth
        circle.stroke()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        
        let key = UserDefaults.Key.isAnimationOnAppearEnabled
        if let isAnimationEnabled = UserDefaults.standard.value(forKey: key) as? Bool {
            strokeColor = !isAnimationEnabled ? #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) : .red
            
            let title = !isAnimationEnabled ? "On" : "Off"
            setTitle(title, for: .normal)
            
            let titleColor = !isAnimationEnabled ? #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) : .red
            setTitleColor(titleColor, for: .normal)
        }
    }
}
