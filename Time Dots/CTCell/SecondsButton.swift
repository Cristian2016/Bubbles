import UIKit

enum ShapeShifterKind {
    case circle
    case square(radius:CGFloat = 26)
}

extension ShapeShifterKind:Equatable { }

protocol ShapeShifter {
    var kind:ShapeShifterKind { get set }
}

class SecondsButton: UIButton, ShapeShifter, HasCover {
    // MARK: - HasCover protocol
    var coverSuperview: UIView { self }
    lazy var cover:TimeComponentLabel_Cover = {
        let timeComponentLabel_Cover = TimeComponentLabel_Cover()
        timeComponentLabel_Cover.color = color
        return timeComponentLabel_Cover
    }()
    
    // MARK: - 
    var color = UIColor.green
    var kind = ShapeShifterKind.circle {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        let shape:UIBezierPath
        switch kind {
        case .circle:
            shape = UIBezierPath(ovalIn: rect)
        case .square(radius: let radius):
            shape = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        }
        color.setFill()
        shape.fill()
    }
    
    // MARK: - setup pause sticker
    private(set) var pauseSticker:PausedSticker!
    func hidePauseLine(_ hide:Bool) { pauseSticker.alpha = hide ? 0 : 1 }
    
    //must be behind button's label and hidden by default
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPausedSticker()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPausedSticker()
    }
    
    //put sticker behind title label
    private func setupPausedSticker() {
        pauseSticker = PausedSticker()
        pauseSticker.alpha = 0.0
        pauseSticker.isUserInteractionEnabled = false
        insertSubview(pauseSticker, at: 0)
        pauseSticker.pinOnAllSidesToSuperview()
    }
}
