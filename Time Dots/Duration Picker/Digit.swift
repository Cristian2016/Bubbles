import UIKit

class Digit: UIButton {
    
    public enum State {
        case enabled
        case disabled
        case hidden
    }
    
    public var buttonState = State.enabled {didSet{setNeedsDisplay()}}
    
    public var fillColor:UIColor?
    
    override func draw(_ rect: CGRect) {
        switch buttonState {
        case .enabled:
            isEnabled = true
            fillColor?.setFill()
        case .disabled:
            isEnabled = false
            fillColor?.withAlphaComponent(0.3).setFill()
        case .hidden:
            isEnabled = false
            #colorLiteral(red: 0.5738074183, green: 0.5655357838, blue: 0, alpha: 0).setFill()
        }
        
        let circle = UIBezierPath(ovalIn: rect)
        circle.fill()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
}

