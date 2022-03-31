//
//  TimeComponentLabel.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Fri  26.02.2021.
//

import UIKit

class TimeComponentLabel: UILabel, ShapeShifter, HasCover {
    var coverSuperview: UIView { self }
    lazy var cover:TimeComponentLabel_Cover = {
        let timeComponentLabel_Cover = TimeComponentLabel_Cover()
        timeComponentLabel_Cover.color = color
        return timeComponentLabel_Cover
    }()
    
    var color = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) {didSet{ setNeedsDisplay() }}
    var kind:ShapeShifterKind = .circle {didSet{ setNeedsDisplay() }}

    override func draw(_ rect: CGRect) {
        let path:UIBezierPath
        switch kind {
        case .circle:
            path = UIBezierPath(ovalIn: rect)
        case .square(radius: let radius):
            path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        }
        color.setFill()
        path.fill()
        
        //is this ok??
        /* ⚠️ */ super.draw(rect)
    }
}

///simple circle that covers the label text when timer enters duration edit mode
class TimeComponentLabel_Cover: UIView {
    var color = UIColor.clear {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        let circle = UIBezierPath(ovalIn: rect)
        color.setFill()
        circle.fill()
    }
    
    func setupYourself(in superview:UIView) {
        superview.layoutIfNeeded() //⚠️ call it otherwise self.size is zero!
        frame = superview.bounds
        superview.addSubviewInTheCenter(self)
        backgroundColor = .clear
        
        isUserInteractionEnabled = false
    }
}

protocol HasCover:AnyObject {
    var coverSuperview:UIView { get }
    var cover:TimeComponentLabel_Cover { get set }
    
    ///implemented in the protocol extension as default implementation
    func showCover(_ show:Bool, _ color:UIColor?)
}

extension HasCover {
    //default implementation
    func showCover(_ show:Bool, _ color:UIColor?) {
        if show && cover.superview == nil {
            cover.setupYourself(in: coverSuperview)
        }
        
        cover.color = show ? (color ?? .clear) : .clear
        cover.isHidden = show ? false : true
    }
}
