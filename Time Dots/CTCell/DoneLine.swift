//
//  DoneLine.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 20.01.2022.
//

import UIKit

class DoneLine: UIView {
    let rotationAngle = CGFloat.pi/7
    let nibName = "DoneLine"
    
    // MARK: - Outlets
    @IBOutlet var container: UIView!
    
    @IBOutlet weak var line0: UIView! {didSet{ line0.alpha = 0 }}
    @IBOutlet weak var line1: UIView!
    
    // MARK: - Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLines()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
        setupLines()
    }
    
    // MARK: - Methods
    private func setupInit() {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard
            let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView
        else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
        
        //set here restorationIdentifier
        restorationIdentifier = "doneLine"
    }
    
    ///rotates them
    private func setupLines() {
        line0.transform = CGAffineTransform(rotationAngle: rotationAngle)
        line1.transform = CGAffineTransform(rotationAngle: -rotationAngle)
    }
}
