//
//  Note.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 07.04.2022.
//

import UIKit

///Pair/Bubble Sticky Notes to simplify stuff
class Note: UIView {
    @IBOutlet var container:UIView!
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let nibFile = UINib(nibName: "Note", bundle: nil)
        guard let nibView = nibFile.instantiate(withOwner: self).first as? UIView else { fatalError() }
        container = nibView
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.frame = bounds
        addSubview(container)
    }
    
    // MARK: - Methods
    func setLineWidth(to width:CGFloat) {
        let lineWidth = max(0, width) //prevent negative values
        background.frame = background.frame.concentric(x: .absolute(lineWidth), y: .absolute(lineWidth))
    }
    
    func setLineColor(to color:UIColor) {
        background.backgroundColor = color
    }
    
    func setCornerRadius(to radius:CGFloat) {
        let cornerRadius = max(0, radius)
        background.layer.cornerRadius = cornerRadius
    }
    
    ///adds shadow only if dark mode OFF
    func setShadow(_ shadow:Bool) {
        let shadowColor = #colorLiteral(red: 0.5741485357, green: 0.5741624236, blue: 0.574154973, alpha: 0.1990829367)
        
        if shadow && !isDarkModeOn {
            label.layer.shadowOffset = CGSize(width: 1, height: 1)
            label.layer.shadowOpacity = 1
            label.layer.shadowColor = shadowColor.cgColor
        } else {
            label.layer.shadowOpacity = 0
            label.layer.shadowColor = nil
        }
    }
    
    func setBackgroundColor(to backgroundStyle:BackgroundStyle) {
        label.backgroundColor = backgroundStyle.noteColor
    }
    
    enum BackgroundStyle {
        case calendarColor
        case yellow
        case white
        case other(UIColor)
        
        var noteColor:UIColor {
            switch self {
                case .white: return .white
                case .calendarColor: return #colorLiteral(red: 0.9984151721, green: 0.5134793993, blue: 0.4874061974, alpha: 1)
                case .yellow: return #colorLiteral(red: 0.9976117015, green: 0.8907652497, blue: 0.4120309353, alpha: 1)
                case .other(let color): return color
            }
        }
    }
}
