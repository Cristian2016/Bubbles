//
//  UndoLastActionView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 25.01.2022.
//

import UIKit

class UndoLastActionView: UIView {
    @IBOutlet var container: UIView!
    let nibName = "UndoLastActionView"
    
    // MARK: - Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    // MARK: -
    private func setupInit() {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}

class WhiteCircleBackground: UIView {
    override func draw(_ rect: CGRect) {
        let circle = UIBezierPath(ovalIn: rect)
        UIColor.white.setFill()
//        #colorLiteral(red: 1, green: 0.6148628104, blue: 0.5473599596, alpha: 1).setFill()
        circle.fill()
    }
}

class UndoLastActionViewBackground: UIView {
    override func draw(_ rect: CGRect) {
        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        UIColor.white.setFill()
        roundedRect.fill()
    }
}
