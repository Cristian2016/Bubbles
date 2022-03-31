//
//  SecondsSticker.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 19.01.2022.
//

import UIKit
import SwiftUI

class SecondsSticker: UIView {
    enum Kind {
        case startSticker
        case doneSticker
    }
    
    var kind:Kind = .startSticker {didSet{ setNeedsDisplay() }}
    
    private let nibName = "SecondsSticker"
    @IBOutlet var container: UIView!
    @IBOutlet weak var symbol: UIImageView!
    
    // MARK: - Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
//    override func draw(_ rect: CGRect) {
//        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 8)
//        
//        let color:UIColor
//        switch kind {
//        case .startSticker: color = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
//        case .doneSticker: color = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
//        }
//        
//        color.setFill()
//        roundedRect.fill()
//    }
    
    // MARK: - Methods
    private func setupInit() {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}
