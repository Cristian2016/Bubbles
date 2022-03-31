//
//  TitleSymbol.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 18.01.2022.
//

import UIKit

class TitleSymbol: UIView {
    @IBOutlet var container: UIView!
    @IBOutlet weak var stack: UIStackView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var symbol: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    private func setupInit() {
        let nib = UINib(nibName: "TitleSymbol", bundle: nil)
        guard
            let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView
        else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}
