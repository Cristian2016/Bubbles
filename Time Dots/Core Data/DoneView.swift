//
//  DoneView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 29.01.2022.
//

import UIKit

class DoneView: UIView {
    let nibName = "DoneView"
    
    var sessionCountBackgroundColor:UIColor! {didSet{
        sessionCountBackground.backgroundColor = sessionCountBackgroundColor
    }}
    var sessionCount:Int! {didSet{
        sessionsCountImageView.image = UIImage(named: String(sessionCount))
    }}
    
    @IBOutlet var container: UIView!
    
    @IBOutlet weak var sessionsCountImageView: UIImageView!
    
    @IBOutlet weak var sessionCountBackground: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    private func setupInit() {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}
