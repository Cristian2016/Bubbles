//
//  BubbleNoteView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 09.04.2022.
//

import UIKit
import SwiftUI


class BubbleNoteView: UIView {
    // MARK: -
    @IBOutlet var container: UIView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var label: UILabel!
    
    // MARK: -
    lazy var pan:UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        addGestureRecognizer(pan)
        return pan
    }()
    
    lazy var tap:UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        return tap
    }()
    
    // MARK: -
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNIB()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNIB()
    }
    
    //setup NIB and gestures
    private func setupNIB() {
        let nibFile = UINib(nibName: "BubbleNoteView", bundle: nil)
        guard let nibView = nibFile.instantiate(withOwner: self).first as? UIView else { fatalError() }
        container = nibView
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.frame = bounds
        addSubview(container)
    }
}

extension BubbleNoteView {
    //whenever new mode set, this method gets called
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection !=  /* currrent */ traitCollection { addShadow() }
    }
}
