//
//  HintView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 29.01.2022.
//

import UIKit

class HintView: UIView {
    private let id = "HintView"
    let nibName = "HintView"
    private var hintViewOutlets:HintViewOutlets!
    
    // MARK: - Outlets
    @IBOutlet var container: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var gestureTargetLabel: UILabel!
    @IBOutlet weak var userIntentLabel: UILabel!
    
    func setOutlets(_ hintViewOutlets:HintViewOutlets ) {
        let image = UIImage(named: hintViewOutlets.imageString ?? "")
        imageView.image = image
        
        titleLabel.text = hintViewOutlets.title
        gestureLabel.text = hintViewOutlets.gestureString
        gestureTargetLabel.text = hintViewOutlets.gestureTargetString
        userIntentLabel.text = hintViewOutlets.userIntent
    }
    
    // MARK: - Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    private func setupInit() {
        self.restorationIdentifier = id
        
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
    }
}

///populate HinView in a nicer way :)
struct HintViewOutlets:Identifiable {
    let id = UUID()
    
    var imageString:String?
    var title:String?
    var gestureString:String?
    var gestureTargetString:String?
    var userIntent:String?
    
    init(_ imageString:String? = nil, _ title:String?, _ gestureString:String?, _ gestureTargetString:String?, _ userIntent:String?) {
        self.imageString = imageString
        self.title = title
        self.gestureString = gestureString
        self.gestureTargetString = gestureTargetString
        self.userIntent = userIntent
    }
}
