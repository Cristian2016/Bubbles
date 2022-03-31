import UIKit

///converts needle into time components

public func userFriendlyTime(from timeComponents:(hr:Int, min:Int, sec:Int)) -> String {
    var hr = String.empty
    var min = String.empty
    if timeComponents.hr > 0 {
        hr = String(timeComponents.hr) + " Hr "
    }
    if timeComponents.min > 0 {
        min = String(timeComponents.min) + " Min "
    }
    let sec = String(timeComponents.sec) + " Sec"
    return hr+min+sec
}

public extension UIView {
    var centerInOwnCoordinateSpace:CGPoint {
        CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    var centerInSuperviewCoordinateSpace:CGPoint {
        center
    }
}

public extension CABasicAnimation {
    static func rotate360(_ duration:CFTimeInterval, startAngle:CGFloat, delegate:CAAnimationDelegate) -> CABasicAnimation {
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        
        fullRotation.fromValue = startAngle
        fullRotation.toValue = 2*CGFloat.pi
        fullRotation.duration = duration
        
        fullRotation.isRemovedOnCompletion = false
        fullRotation.fillMode = .forwards
        
        /* i need to know when animation stops */
        fullRotation.delegate = delegate
        
        return fullRotation
    }
}

public extension UIColor {
    class var ultraLightGray:UIColor {return UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)}
    class var roseRed:UIColor {return UIColor(red: 253/255, green: 77/255, blue: 82/255, alpha: 1)}
    class var brightGreen:UIColor {return UIColor(red:29/255, green:222/255, blue:79/255, alpha: 1)}
    class var brightOrange:UIColor {return UIColor(red: 253/255, green: 168/255, blue: 9/255, alpha: 1)}
}

public extension NSLayoutConstraint {
    ///subview has bottom top leading trailing constraints eaqual to its superview
    static func pinTo(_ superView: UIView, _ subview:UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: subview, attribute: .bottom, relatedBy: .equal, toItem: superView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: subview, attribute: .top, relatedBy: .equal, toItem: superView, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: subview, attribute: .leading, relatedBy: .equal, toItem: superView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: subview, attribute: .trailing, relatedBy: .equal, toItem: superView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
    }
    
    static func pinToCenter(_ superView: UIView, _ subview:UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: subview, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: subview, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: subview, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0).isActive = true
    }
}
