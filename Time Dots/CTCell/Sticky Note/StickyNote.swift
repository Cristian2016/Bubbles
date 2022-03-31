//
//  StickyNote.swift
//  StickyNote
//
//  Created by Cristian Lăpușan on Wed  7.04.2021.
//

import UIKit

class StickyNote: UIView {
    @IBOutlet var container: UIView! {didSet{ setShadow(isDarkModeOn) }}
    @IBOutlet weak var fixBackground: ColorBackground!
    @IBOutlet weak var slidingBackground: ColorBackground!
    @IBOutlet weak var field: UITextField! {didSet{
        //customize field
        field.setupAsStickyNote()
        field.delegate = self
    }}
    
    private var slideDirection = SlideDirection.none {didSet{ setupSliding() }}
    
    func customize(outerColor:UIColor = .white,
                 outerShape:ColorBackground.Shape = .oval,
                 outerBorder:ColorBackground.Border = .thin,
                 innerColor:UIColor = .blue,
                 innerShape:ColorBackground.Shape = .oval,
                 innerBorder:ColorBackground.Border = .thin,
                 slideDirection:SlideDirection = .none) {
        
        slidingBackground.customize(outerColor, outerShape, outerBorder)
        fixBackground.customize(innerColor, innerShape, innerBorder)
        self.slideDirection = slideDirection
    }
    
    var actionTriggerSlideDistance = CGFloat(60)
    var actionForSlide:(()->())?
    var maximumStickyNoteLenght = 8
    
    // MARK: - Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Private
    private func setup() {
        guard
            let nibView = Bundle.main.loadNibNamed("StickyNote", owner: self, options: nil)?.first as? UIView
        else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
    
    private func setShadow(_ darkModeOn:Bool, opacity:Float = 0.5) {
        self.layer.shadowOpacity = darkModeOn ? 0.0 : opacity
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
    }
    
    private func setupSliding() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSlide(_:)))
        slidingBackground.addGestureRecognizer(panGesture)
    }
    
    @objc private func handleSlide(_ pan:UIPanGestureRecognizer) {
        switch pan.state {
        case .began: break
        case .changed:
            let translation = pan.translation(in: pan.view)
            slidingBackground.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            field.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            if translation.x >= actionTriggerSlideDistance {
                (actionForSlide ?? { })()
            }
            
        case .cancelled, .ended:
            UIView.animate(withDuration: 0.1) {[weak self] in
                self?.slidingBackground.transform = .identity
                self?.field.transform = .identity
            }
        default: break
        }
    }
    
    // MARK: - enum
    enum SlideDirection {
        case up(limit:CGFloat)
        case down(limit:CGFloat)
        case right(limit:CGFloat)
        case left(limit:CGFloat)
        case none
    }
    
    // MARK: - override
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setShadow(isDarkModeOn)
        }
    }
}

///used to create the slider button effect
class ColorBackground: UIView {
    enum Border {
        case thin
        case medium
        case thick
        case custom(thickness:CGFloat)
        case none
    }
    
    enum Shape {
        case oval
        case rectangle(cornerRadius:CGFloat)
    }
    
    func customize(_ color:UIColor = .white,
                   _ shape:Shape = .rectangle(cornerRadius: 0),
                   _ border:Border = .none) {
    
    self.color = color
    self.shape = shape
    self.border = border
    self.backgroundColor = .clear
    setNeedsDisplay()
}
    
    var color:UIColor = .white {didSet{ setNeedsDisplay() }}
    private(set) var border = Border.none
    private(set) var shape = Shape.rectangle(cornerRadius: 0)
    
    override func draw(_ rect: CGRect) {
        var path:UIBezierPath
        
        let lineWidth:CGFloat
        
        switch border {
        case .none: lineWidth = 0
        case .thin: lineWidth = 2
        case .medium: lineWidth = 4
        case .thick: lineWidth = 6
        case .custom(thickness: let thickness): lineWidth = thickness
        }
        
        let insetRect = rect.insetBy(dx: lineWidth, dy: lineWidth)
        switch shape {
        case .oval:
            path = UIBezierPath(ovalIn: insetRect)
            
        case .rectangle(cornerRadius: let radius):
            path = UIBezierPath(roundedRect: insetRect, cornerRadius: radius)
        }
        
        color.setFill()
        path.fill()
        
        UIColor.white.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

// MARK: - TextFieldDelegate Delegate
extension StickyNote:UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.restorationIdentifier != "calendarSticker" ? true : false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        notifyTextFieldDidBeginEditing()
        UserFeedback.triggerSingleHaptic(.soft)
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if let existingText = textField.text {
            return allowOnlyCharacters(maximumStickyNoteLenght, existingText, enteredText: string)
        }
        return false
    }
    
    //user touched enter key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //textFieldShouldReturn called before textFieldDidEndEditing
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        
        switch textField.restorationIdentifier! {
        case "pairCell":
            /* tell cell new sticky added */
            (superview?.superview as? PairCell)?.checkSticky = true
            
        case "ctCell":
            /* tell cell new sticky added */
            (superview?.superview as? CTCell)?.checkSticky = true
            
        default: break
        }
    }
        
    // MARK: - helpers
    private func allowOnlyCharacters(_ maximumStickyNoteLenght:Int,
                                     _ existingText:String,
                                     enteredText:String) -> Bool {
        
        let deletePressed = (enteredText.unicodeScalars.first?.description == nil) ? true : false
        return (existingText.count < maximumStickyNoteLenght || deletePressed) ? true : false
    }
    
    private func notifyTextFieldDidBeginEditing() {
        let name = Post.textFieldDidBeginEditing
        NotificationCenter.default.post(name: name, object: self)
    }
}
