import UIKit

class OKButton: UIButton {
    
    struct ExtraText {
        let topText:String
        let bottomText:String
    }
    
    let color:UIColor
    let extraText:ExtraText?
    private let title = "Ok"
    private let restorationID = "OKButton"
    
    var swipeUp:UISwipeGestureRecognizer!
    var swipeDown:UISwipeGestureRecognizer!
    var swipeRight:UISwipeGestureRecognizer!
    var swipeLeft:UISwipeGestureRecognizer!
    
    private func setupSwipeGestures() {
        swipeUp = UISwipeGestureRecognizer()
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
        
        swipeDown = UISwipeGestureRecognizer()
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)
        
        swipeRight = UISwipeGestureRecognizer()
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
        
        swipeLeft = UISwipeGestureRecognizer()
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)
    }
    
    init(_ color:UIColor, _ extratext:ExtraText? = nil) {
        self.color = color
        self.extraText = extratext
        
        super.init(frame: .zero)
        //⚠️ frame zero here!
        
        restorationIdentifier = restorationID
        
        setupSwipeGestures()
        
        registerFor_DidBecomeActive()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ rect: CGRect) {
        
        let circle = UIBezierPath(ovalIn: rect)
        color.setFill()
        circle.fill()
    }
    
    public enum Toggle {
        case remove
        case add
    }
    
    public func toggle(_ toggleKind:Toggle, _ superview:UIView, animated:Bool = false) {
        
        switch toggleKind {
        case .add/* to view */:
            
            //make sure you don't add okButton more than once
            guard superview.subviews.last?.restorationIdentifier != "okButton" else { return }
            
            let frame = CGRect(x: 3, y: 3, width: superview.frame.width - 6.0, height: superview.frame.width - 6.0)
            self.frame = frame
            superview.addSubview(self)
            if alpha == 0 { alpha = 1.0 }
            self.reverseToIdentity()
            setTitle(title, for: .normal)
            
        case .remove/* from view */:
            if !animated { self.removeFromSuperview() }
            else {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: []) {
                    self.alpha = 0.0
                    self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                } completion: { _ in
                    self.reverseToIdentity()
                    self.removeFromSuperview()
                }
            }
        }
    }
    
    private func reverseToIdentity() {
        if self.transform != .identity { self.transform = .identity }
    }
    
    //shown exactly 3 times for editDurationVC and durationPickerVC
    private func setupExtraLabels(_ extratext:ExtraText) {
        guard frame != .zero else { fatalError("frame zero! change place where this call should take place such as layoutsubvies etc") }
        
        let height = frame.height
        let centerYOffset = height * 0.25
        
        let topLabel = UILabel()
        topLabel.text = extratext.topText
        topLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        topLabel.textColor = .white
        topLabel.textAlignment = .center
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLabel)
        
        topLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        topLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -centerYOffset).isActive = true
        
        let bottomlabel = UILabel()
        bottomlabel.text = extratext.bottomText
        bottomlabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        bottomlabel.textColor = .white
        bottomlabel.textAlignment = .center
        bottomlabel.numberOfLines = 0
        
        bottomlabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomlabel)
        
        bottomlabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        bottomlabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: centerYOffset * 1.1).isActive = true
    }
    
    //here is the place to add things that need the view's frame, such as constraints
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.font = UIFont.systemFont(ofSize: self.frame.width * 0.3 , weight: .regular)
        if let extratext = extraText { setupExtraLabels(extratext) }
    }
}

extension OKButton {
    //make sure okButton pulsates all the time
    private func registerFor_DidBecomeActive() {
        let name = UIApplication.didBecomeActiveNotification
        NotificationCenter.default.addObserver(forName: name, object: /* ⚠️ */ nil, queue: nil) {
            [weak self] _ in
            
            self?.pulsateAnimate()
        }
    }
}
