import UIKit

struct UITweaks {
    public enum Toggle {
        case on
        case off
    }
    
    /*I apply drop shadow not to the container view but to the main view*/
    public static func toggleDropShadow(_ toggle:Toggle, for view:UIView) {
        guard
            let mainView = view.subviews.first,
            mainView.restorationIdentifier == "mainView"
        else { return }
        
        let shadowColor = view.isDarkModeOn ? UIColor.clear : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        mainView.layer.shadowColor = (toggle == .on) ? shadowColor.cgColor : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        mainView.layer.shadowOffset = (toggle == .on) ? CGSize(width: 3, height: 6) : CGSize(width: 0, height: -3)
        mainView.layer.shadowOpacity = (toggle == .on) ?  0.5 : 0.0
    }
    public static func rotateAtRandom(_ view:UIView, degreeValues:[Int:Int]?) {
        if let degreeValues = degreeValues {
            let rotationValue = degreeValues[Int(arc4random_uniform(UInt32(degreeValues.count)))]
            view.transform = CGAffineTransform(rotationAngle: CGFloat.pi/CGFloat(rotationValue ?? 40))
        }
    }
    
    private init() {}
}
