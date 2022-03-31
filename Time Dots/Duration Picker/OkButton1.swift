//
//  OkButton1.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 13.01.2022.
//

import UIKit

class OkButton1: UIView {
    @IBOutlet var container: UIView!
    @IBOutlet weak var okCircle: OKCircle!
    
    @IBOutlet weak var okLabel: UILabel!
    @IBOutlet weak var arrowLeft: UIImageView!
    @IBOutlet weak var arrowUp: UIImageView!
    
    @IBOutlet weak var topLabel: UILabel! {didSet{
        topLabel.isHidden = true
    }}
    @IBOutlet weak var bottomLabel: UILabel! {didSet{
        bottomLabel.isHidden = true
    }}
    
    //circle color
    var color:UIColor! {didSet{
        okCircle.color = color
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNibView()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNibView()
        setupGestures()
    }
    
    private func setupNibView() {
        let nib = UINib(nibName: "OKButton1", bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
    
    // MARK: - gestures
    var tap:UITapGestureRecognizer!
    
    var swipeUp:UISwipeGestureRecognizer!
    var swipeDown:UISwipeGestureRecognizer!
    var swipeLeft:UISwipeGestureRecognizer!
    var swipeRight:UISwipeGestureRecognizer!
    
    private func setupGestures() {
        tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        
        swipeUp = UISwipeGestureRecognizer()
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
        
        swipeDown = UISwipeGestureRecognizer()
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)
        
        swipeLeft = UISwipeGestureRecognizer()
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)
        
        swipeRight = UISwipeGestureRecognizer()
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
    }
}

class OKCircle:UIView {
    var color:UIColor!
    var circlePath:UIBezierPath!
    
    override func draw(_ rect: CGRect) {
        circlePath = UIBezierPath(ovalIn: rect)
        color.setFill()
        circlePath.fill()
    }
}
