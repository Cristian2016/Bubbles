//
//  DeleteActionVC.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 26.01.2022.
//

import UIKit
import CoreData
import WidgetKit

class DeleteActionVC: UIViewController {
    static let id = "DeleteActionVC"
    
    var isContainerBelowEditedCell: Bool!
    @IBOutlet weak var containerCenterYAnchor: NSLayoutConstraint!
    
    // MARK: - Payload
    var bubbleID:String!
    var bubbleIndexPath:IndexPath!
    var sessionsCount:Int!
    var bubbleColor:String!
    var centerY:CGFloat!
    var cellFrame: CGRect!
    var bubbleDescription:String!
    
    private func cttvc() -> CTTVC {
        guard let cttvc = (presentingViewController as? UINavigationController)?.viewControllers.first as? CTTVC else { fatalError() }
        return cttvc
    }
    
    // MARK: -
    @IBAction func deleteBubble(_ sender: UIButton) {
        UserFeedback.triggerSingleHaptic(.medium)
        
        cttvc().deleteBubble(at: bubbleIndexPath)
        presentingViewController?.dismiss(animated: false)
    }
    
    @IBAction func deleteHistory(_ sender: UIButton) {
        if sessionsCount == 0 { return }
        UserFeedback.triggerSingleHaptic(.medium)
        
        cttvc().eraseHistoryForBubble(at: bubbleIndexPath)
        presentingViewController?.dismiss(animated: false)
    }
    
    @IBOutlet weak var historyButton: UIButton! {didSet{
        historyButton.tintColor = UIColor(named: bubbleColor + "Intense")
        
        if sessionsCount == 0 {
            historyButton.alpha = 0.4
            historyButton.isUserInteractionEnabled = false
        }
        
        let string = attributedString("History", fontSize: 28)
        historyButton.setAttributedTitle(string, for: .normal)
    }}
    
    @IBOutlet weak var bubbleButton: UIButton! {didSet{
        bubbleButton.tintColor = UIColor(named: bubbleColor + "Intense")
        
        let fontSize:CGFloat = (bubbleDescription.count <= 8) ? 28 : 24
        //only this works for UIButton below iOS 15
        let string = attributedString(bubbleDescription, fontSize: fontSize)
        bubbleButton.setAttributedTitle(string, for: .normal)
        bubbleButton.titleLabel?.numberOfLines = 1
    }}
    
    @IBOutlet weak var bubbleColorView: BubbleColorView! {didSet{
        bubbleColorView.fillColor = UIColor(named: bubbleColor + "Intense") ?? .white
    }}
    
    // MARK: - FlipCardProtocol
    @IBOutlet weak var background: TableBackground! {didSet{
        background.alpha = 0
        background.color = UIColor(named: "backgroundColor") ?? .green
    }}
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupContainer_FlipGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delayExecution(.now()) { self.positionContainer() }
    }
    
    // MARK: - helpers
    ///using it since it does not work 
    private func attributedString(_ title:String, fontSize:CGFloat = 30) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        let attributes = [NSAttributedString.Key.font : font]
        let attributedString = NSMutableAttributedString(string: title, attributes: attributes)
        return attributedString
    }
}

extension DeleteActionVC:FlippingBackground {
    func setupContainer_FlipGestures() {
        let action = #selector(handleFlip(_:))
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: action)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: action)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: action)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: action)
        
        swipeUp.direction = .up
        swipeDown.direction = .down
        swipeLeft.direction = .left
        
        container.addGestureRecognizer(swipeUp)
        container.addGestureRecognizer(swipeDown)
        container.addGestureRecognizer(swipeLeft)
        container.addGestureRecognizer(swipeRight)
    }
    
    func positionContainer() {
        let cellBottomEdgeY = cellFrame.origin.y + cellFrame.height
        let cellTopEdgeY = cellFrame.origin.y
        
        let containerFrame = container.absoluteFrame()
        let containerCenter = container.absoluteCenter()
        
        isContainerBelowEditedCell = background.frame.height * backgroundScaleUpValue <= (view.frame.height - cellBottomEdgeY)
        
        //wantedCenter
        let wantedCenterY = isContainerBelowEditedCell ?
        cellBottomEdgeY + containerFrame.height/2  :
        cellTopEdgeY - containerFrame.height/2
        
        let delta = abs(containerCenter.y - wantedCenterY)
        let translationY = (containerCenter.y <= wantedCenterY) ? delta : -delta
        
        //update anchor
        view.layoutIfNeeded()
        containerCenterYAnchor.constant += translationY
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction]) {[weak self] in
            self?.container.alpha = 1
        } completion: { _ in
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func handleFlip(_ swipe:UISwipeGestureRecognizer) {
        UIView.transition(with: container, duration: 0.3, options: [.allowUserInteraction, .showHideTransitionViews, .transitionFlipFromTop]) {
            self.container.alpha = 0
        } completion: { _ in
//            self.container.alpha = 1
        }
        
        UIView.transition(with: textView, duration: 0.3, options: [.allowUserInteraction, .showHideTransitionViews, .transitionFlipFromTop]) {
            self.textView.isHidden = false
        } completion: { _ in
        }
    }
}

extension DeleteActionVC {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: background) else { return }
        if !background.path.contains(location) {
            presentingViewController?.dismiss(animated: false)
        }
    }
}

class Background: UIView {
    var path:UIBezierPath!
    var fillColor:UIColor = UIColor.white {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        path = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        fillColor.setFill()
        path.fill()
    }
}

class BubbleColorView:UIView {
    var fillColor:UIColor = .white
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        path.fill()
    }
}
