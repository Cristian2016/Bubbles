//
//  HMSHeader.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 10.01.2022.
//

import UIKit

class HMSHeader: UIView {
    @IBOutlet weak var container:UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        let nib = UINib(nibName: "HMSHeader", bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}
