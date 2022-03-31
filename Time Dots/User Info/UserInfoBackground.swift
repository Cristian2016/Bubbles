//
//  UserInfoBackground.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 21.04.2021.
//

import UIKit

class UserInfoBackground: UIView {
    
    @IBInspectable var lineWidth:CGFloat = 6
    @IBInspectable var strokeColor:UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    @IBInspectable var cornerRadius:CGFloat = 20
    
    override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: lineWidth/2, dy: lineWidth/2), cornerRadius: cornerRadius)
        path.lineWidth = lineWidth
        strokeColor.setStroke()
        if isDarkModeOn {
            UIColor.white.setFill()
        } else {
            UIColor.systemBackground.setFill()
        }
        path.stroke()
        path.fill()
    }
}
