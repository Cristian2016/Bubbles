//
//  SectionCell.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Fri  26.03.2021.
//

import UIKit

class TopCell: UICollectionViewCell {
    
    private let darkColors = ["Sour Cherry", "Ultramarine", "Charcoal", "Purple", "Chocolate", "Byzantium"]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
//        print("TopCell deinit")
    }
    
    @IBOutlet weak var durationStack: UIStackView!
    
    @IBOutlet var allDurationLabels: [UILabel]!
    
    static let reuseID = "topCell"
    
    // MARK: -
    @IBOutlet weak var sessionNumberLabel: UILabel! {didSet{
        sessionNumberLabel.adjustsFontSizeToFitWidth = true
    }}
    
    @IBOutlet weak var dayLabel: UILabel!
    
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    
    @IBOutlet weak var hoursStack: UIStackView!
    @IBOutlet weak var minutesStack: UIStackView!
    @IBOutlet weak var secondsStack: UIStackView!
    
    @IBOutlet weak var bubbleActive: UILabel! {didSet{ registerFor_DidBecomeActive() }}
    @IBOutlet weak var rectView: RectView!
    // MARK: -
    
    var bubbleActiveShouldBlink = false {didSet{
        bubbleActive.blink(bubbleActiveShouldBlink ? true : false, hide: true)
    }}
    
    var color:UIColor? {didSet{
        //set stroke and background color
        rectView.color = color
        dayLabel.textColor = .white
    }}
    
    lazy var textColor = UIColor(named: colorString + "Text")
    
    var colorString:String! {didSet{
        bubbleActive.textColor = textColor
        dayLabel.backgroundColor = textColor
        
        let condition = isDarkModeOn && color == .charcoal
        if condition {
            sessionNumberLabel.textColor = .white
        } else {
            sessionNumberLabel.textColor = isSelected ? .white : textColor ?? .cyan
        }
    }}
    
    private var isCharcoal:Bool { color == .charcoal }
    
    ///when isFill is set to a new value, it triggers a change in the look of that topCell
    var isFill = false {didSet{
        if isDarkModeOn && isCharcoal { sessionNumberLabel.textColor = .white }
        sessionNumberLabel.textColor = isFill ? .white : color ?? .cyan
        rectView.isFill = isFill
        
        dayLabel.textColor = isFill ? textColor : .white
        dayLabel.backgroundColor = isFill ? .white : textColor
                
        if darkColors.contains(colorString) {
            allDurationLabels.forEach { $0.textColor = isFill ? .white : .label}
        }
        
        bubbleActive.textColor = isFill ? .white : textColor
        
        //if timeBubble's color is black
        if isCharcoal {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                bubbleActive.textColor = isFill ? .white : .white
                sessionNumberLabel.textColor = .white
            default:
                bubbleActive.textColor = isFill ? .white : .black
            }
        }
    }}
    
    var stayFill:Bool?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if sessionNumberLabel.textColor == .white {
            sessionNumberLabel.textColor = textColor
        }
        isSelected = false
        isFill = false
        bubbleActive.blink(false)
        bubbleActive.layer.removeAllAnimations()
    }
    
    // MARK: - helper
    func setDuration(_ duration:TimeInterval) {
        let dur = duration.time()
        
        hoursStack.isHidden = (dur.hr == 0) ? true : false
        minutesStack.isHidden = (dur.min == 0) ? true : false
        
        let condition = dur.sec.rounded(.toNearestOrEven) == 0 && !(0...0.5).contains(duration)
        secondsStack.isHidden = condition ? true : false
        
        hoursLabel.text = String(dur.hr)
        minutesLabel.text = String(dur.min)
        secondsLabel.text = String(Int(dur.sec.rounded(.toNearestOrEven)))
    }
}

///it fills circle with color or strokes
class RectView: UIView {
    
    var color:UIColor? {didSet{ setNeedsDisplay() }}
    
    var isFill = false {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        let condition = isDarkModeOn && color == .charcoal
        
        let circlePath = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 9)
        circlePath.lineWidth = 3
        
        isFill ? (color ?? .cyan).setFill() : (condition ? UIColor.white : color?.withAlphaComponent(0.9) ?? .cyan).setStroke()
        isFill ? circlePath.fill() : circlePath.stroke()
    }
}

// MARK: - darkmode lightmode
extension TopCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            guard
                [UIColor.charcoal, .white].contains(sessionNumberLabel.textColor)
            else {return}
            
            let isDark = traitCollection.userInterfaceStyle == .dark
            if !isSelected {
                sessionNumberLabel.textColor = isDark ? .white : .charcoal
            }
        }
    }
}

// MARK: - notification observer
extension TopCell {
    /* whenever app becomes inactive blinking animation stops, so when app active again, animation should resume, right? :) */
    private func registerFor_DidBecomeActive() {
        let name = UIApplication.didBecomeActiveNotification
        NotificationCenter.default.addObserver(forName: name, object: /* ⚠️ */ nil, queue: nil) {
            [weak self] _ in
            guard
                let self = self,
                self.bubbleActiveShouldBlink
            else {return}
            
            //resume blinking, if it should blink!
            self.bubbleActiveShouldBlink = true
        }
    }
}
