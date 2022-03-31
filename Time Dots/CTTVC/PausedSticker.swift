//
//  PausedSticker.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 10.06.2021.
//

import UIKit

class PausedSticker: UIView {
    @IBOutlet var container: UIView!
    
    // MARK: -
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let nibView = Bundle.main.loadNibNamed("PausedSticker", owner: self, options: nil)?.first as? UIView
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.isUserInteractionEnabled = false
        addSubview(container)
    }
}
