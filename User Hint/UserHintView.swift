//
//  UserTip.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 21.01.2022.
//

import UIKit

protocol HintsManagerDelegate : AnyObject {
    var hintView:UserHintView? { get set }
}

///User Hints to let user know what to do in a certain situation
class HintsManager {
    enum Reason {
        case resetTimer
        case palette
    }
    
    enum Position {
        case left
        case right
        case top
        case bottom
        case center
    }
    
    weak var delegate:HintsManagerDelegate?
    
    // MARK: -
    init(_ delegate:HintsManagerDelegate?) {
        self.delegate = delegate
    }
    deinit {
        print("UserHintManager", #function)
    }
    
    // MARK: - Methods
    func toggleHint(for reason:Reason, position:Position = .left, in superview:UIView?) {
        guard
            let superview = superview else { return }
        
        if delegate?.hintView == nil {
            delegate?.hintView = hintView(for: reason)
            let offset = CGPoint(x: -0.20, y: 0)
            let hintView = delegate?.hintView ?? UserHintView()
            superview.addSubViewWithPercentageOffsetFromCenter(hintView, offset)
        } else {
            delegate?.hintView?.removeFromSuperview()
            delegate?.hintView = nil
        }
    }
    func removeHintViewIfNeeded() {
        guard let hintView = delegate?.hintView else { return }
        hintView.removeFromSuperview()
        delegate?.hintView = nil
    }
    
    func hintView(for reason:Reason) -> UserHintView {
        guard let userHint = dict[reason] else {fatalError()}
        
        let frame:CGRect
        switch reason {
        case .resetTimer:
            frame = CGRect(origin: .zero, size: CGSize(width: 178, height: 130))
        case .palette:
            frame = CGRect(origin: .zero, size: CGSize(width: 250, height: 250))
        }
        
        let userHintView = UserHintView(frame: frame)
        userHintView.titleLabel.text = userHint.title
        userHintView.gestureLabel.text = userHint.gesture
        userHintView.subtitleLabel.text = userHint.subtitle
        
        userHintView.enableAutolayout(false)
        
        return userHintView
    }
    
    let dict:[Reason:UserHint] = [
        .resetTimer : UserHint(title: "Reset Timer",
                               gesture: "Tap & Hold",
                               subtitle: "on Seconds"),
        .palette : UserHint(title: "➀ Stopwatch ➁ Bubble",
                            gesture: "➀ Tap ➁ Touch & Hold",
                            subtitle: "")
    ]
}

struct UserHint {
    let title:String
    let gesture:String
    let subtitle:String
}

class UserHintView: UIView {
    private let nibName = "UserHintView"
    static let id = "userHint"
    @IBOutlet var container: UIView!
    @IBOutlet weak var background: UserHintBackground! {didSet{
        background.addShadow(color:.black.withAlphaComponent(0.5))
    }}
    
    @IBOutlet weak var stack:UIStackView!
    
    @IBOutlet weak var titleLabel: UILabel! {didSet{
        titleLabel.textColor = UIColor(named: "userHintTitle")
    }}
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel! {didSet{
        subtitleLabel.textColor = UIColor(named: "userHintSubtitle")
    }}
    
    // MARK: - Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    // MARK: - Methods
    private func setupInit() {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError() }
        
        container = nibView
        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)
        
        enableAutolayout(true)
        restorationIdentifier = UserHintView.id
    }
}

class UserHintBackground: UIView {
    let color = UIColor(named: "userHintBackground") ?? .green
    let radius = CGFloat(12)
    
    override func draw(_ rect: CGRect) {
        let concentricRect = rect.concentric(x: .absolute(-2), y: .absolute(-2))
        let roundedRect = UIBezierPath(roundedRect: concentricRect, cornerRadius: radius)
        color.setFill()
        roundedRect.fill()
    }
}
