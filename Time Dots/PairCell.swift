//
//  PairCell.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Mon  29.03.2021.
//

import UIKit
import SwiftUI

class PairCell: UICollectionViewCell {
    deinit { NotificationCenter.default.removeObserver(self) }
    
    internal var initialStickyLabelCenter:CGPoint!
    
    // MARK: -
    weak var delegate:PairCellDelegate?
    
    // MARK: -
    static let reuseID = "pairCell"
    static let nibName = "PairCell"
    
    // MARK: -
    ///alpha values only. no data set here
    func stickyNoteLook(_ sticky:String?, _ isStickyDisplayed:Bool?) {
        guard
            let sticky = sticky,
            let isStickyDisplayed = isStickyDisplayed
        else { return }
        
        if sticky.isEmpty {//stickyNote empty
            noteSymbol.alpha = 0
            stickyLabel.alpha = 0
            stickyLabelDeleteConfirmationLabel.alpha = 0
            
        } else {//sticky note has text
            noteSymbol.alpha = isStickyDisplayed ? 0 : 1
            stickyLabel.alpha = isStickyDisplayed ? 1 : 0
            stickyLabelDeleteConfirmationLabel.alpha = isStickyDisplayed ? 1 : 0
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var container: UIView! {didSet{
        registerFor_DidBecomeActive()
        register_For_Animate_Notification()
    }}
    @IBOutlet weak var colorAccolade: ColorAccolade!
    
    //start
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    //pause
    @IBOutlet weak var pauseTimeLabel: UILabel!
    @IBOutlet weak var pauseDateLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var pairNumberLabel: UILabel!
    @IBOutlet weak var pairNumberBackground: PairNumberBackground!
    
    @IBOutlet weak var stickyLabel: UILabel! {didSet{
        tiltStickyLabel()
        stickyLabel.addShadow()
        setupStickyLabelGestures()
    }}
    
    @IBOutlet weak var stickyLabelDeleteConfirmationLabel: UILabel!
    
    @IBOutlet weak var blinkingCircles: BlinkingCircles!
    
    @IBOutlet weak var noteSymbol: UIImageView!
    
    // MARK: - sticky notes
    var checkSticky = false {didSet{
        canKillKeyboard = true
        //informs the delegate "the user typed a sticky note"
        delegate?.userAddsSticky(for: self, sticky: stickyLabel.text ?? String.empty)
        checkSticky = false
    }}
    
    var canKillKeyboard = false
    
    private(set) var circlesAreBlinking = false
    
    // MARK: - Data
    var pairCellContent:BottomCell.PairCellContent? { didSet{ updateUI() }}
    
    private func updateUI() {
        guard let pair = pairCellContent else { return }
        
        //1. RESET CONTENT FIRST
        //pause time and date might be visible or not
        pauseTimeLabel.text = nil
        pauseDateLabel.text = nil
        //might be visible or not
        durationLabel.text = nil
        //sticky note might be visible or not
        stickyLabel.alpha = 0
        stickyLabelDeleteConfirmationLabel.alpha = 0
        noteSymbol.alpha = 0
        stickyLabel.text = nil //prevent wrong sticky notes to be displayed
        //circles might be present or not
        self.blinkingCircles.blink(false, hide: true)
        
        //2. SET CONTENT
        //start and pause dates and times
        startTimeLabel.text = pair.startT
        startDateLabel.text = pair.startD
        //pause
        if !pair.pauseT.isEmpty {
            pauseTimeLabel.text = pair.pauseT
            pauseDateLabel.text = pair.pauseD
        }
        
        //duration
        if !pair.duration.isEmpty {
            durationLabel.text = pair.duration
            blinkingCircles.alpha = 0
        } else {
            durationLabel.textColor = .clear
            durationLabel.text = "not computed yet"
            pairNumberBackground.color = .systemGray3
            self.blinkingCircles.alpha = 1
            
            self.blinkingCircles.blink(true, hide: false)
            self.circlesAreBlinking = true
        }
        
        //sticky note
        stickyLabel.text = pair.sticky
        
        if !pair.sticky.isEmpty {//use added sticky
            noteSymbol.alpha = !pair.isStickyDisplayed ? 1 : 0
            
            let value:CGFloat = pair.isStickyDisplayed ? 1 : 0
            stickyLabel.alpha = value
            stickyLabelDeleteConfirmationLabel.alpha = value
        }
        else {
            stickyLabel.alpha = 0
            stickyLabelDeleteConfirmationLabel.alpha = 0
        } //no sticky yet
        
        //hide pause date if it's the same with start date
        if pair.startD == pair.pauseD { pauseDateLabel.alpha = 0 }
    }
    
    // MARK: -
    override func prepareForReuse() {
        super.prepareForReuse()
        
        noteSymbol.alpha = 0
        stickyLabel.alpha = 0
        stickyLabelDeleteConfirmationLabel.alpha = 0
        pauseTimeLabel.textColor = .label
        durationLabel.textColor = .label
    }
    
    // MARK: - Configure
    func configure() {
        
    }
}

protocol PairCellDelegate:AnyObject {
    ///time to create a sticky note
    func userAddsSticky(for pairCell:PairCell, sticky:String)
    
    func userDeletesSticky(for pairCell:PairCell)
    
    func userEditsSticky(for pairCell:PairCell)
}

// MARK: - darkmode lightmode
extension PairCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            stickyLabel.addShadow()
            
            guard
                [UIColor.rgb(33, 33, 33), .white].contains(colorAccolade.strokeColor)
            else {return}
            
            let isDark = traitCollection.userInterfaceStyle == .dark
            colorAccolade.set(strokeColor: isDark ? .white : UIColor.rgb(33, 33, 33))
        }
    }
}

// MARK: - notification observer
extension PairCell {
    /* whenever app becomes inactive blinking animation stops,
     so when app active again, animation should resume, right? :) */
    private func registerFor_DidBecomeActive() {
        let name = UIApplication.didBecomeActiveNotification
        NotificationCenter.default.addObserver(forName: name, object: /* ⚠️ */ nil, queue: nil) {
            [weak self] _ in
            guard
                let self = self,
                self.circlesAreBlinking
            else {return}
            
            //resume blinking, if it should blink!
            self.blinkingCircles.blink(true, hide: false)
        }
    }
}

// MARK: - notification observer
extension PairCell {
    func register_For_Animate_Notification() {
        NotificationCenter.default.addObserver(forName: Post.animatePairCell, object: nil, queue: nil) {[weak self] notification in
            
            self?.layer.removeAllAnimations()
            if notification.object as? PairCell === self { self?.animate() }
        }
    }
    private func animate() {
        if layer.animationKeys() == nil {
            delayExecution(.now() + 0.1) {
                self.layer.zPosition = 1
                self.pulsateAnimate(maximumScale: 1.2, duration: 4)
            }
        }
        else {
            layer.zPosition = 0
            layer.removeAllAnimations()
        }
    }
}

extension PairCell {
    ///add pan to delete sticky and a tap gesture
    func setupStickyLabelGestures() {
        let pan = Pan(target: self, action: #selector(deleteStickyNote(_:)))
        let tap = Tap(target: self, action: #selector(editStickyNote(_:)))
        
        stickyLabel.addGestureRecognizer(pan)
        stickyLabel.addGestureRecognizer(tap)
    }
    
    @objc func deleteStickyNote(_ gesture:Pan) {
        switch gesture.state {
            case .began:
                initialStickyLabelCenter = gesture.view?.center
            case .changed:
                let /* finger */translationX = gesture.translation(in: self).x
                gesture.view?.center.x += translationX
                gesture.setTranslation(.zero, in: self)
                if gesture.view!.center.x <= 20 {
                    gesture.state = .ended
                    delegate?.userDeletesSticky(for: self)
                    stickyLabel.alpha = 0
                    stickyLabelDeleteConfirmationLabel.text = "Done!"
                    stickyLabelDeleteConfirmationLabel.backgroundColor = UIColor(named: "Confirm")
                    
                    UIView.animate(withDuration: 2) {
                        [weak self] in
                        self?.stickyLabelDeleteConfirmationLabel.alpha = 0
                        UserFeedback.triggerSingleHaptic(.heavy)
                    } completion: {[weak self] done in
                        self?.stickyLabelDeleteConfirmationLabel.text = "Delete"
                        self?.stickyLabelDeleteConfirmationLabel.backgroundColor = .red
                    }
                }
            case .ended:
                gesture.view?.center = initialStickyLabelCenter
            default: break
        }
    }
    
    ///show SwiftUI StickiesView
    @objc func editStickyNote(_ gesture:Tap) {
        if gesture.state == .ended {
            delegate?.userEditsSticky(for: self)
            UserFeedback.triggerSingleHaptic(.light)
//            pulsateAnimate() //animate so the user notices which pair is being edited
        }
    }
    
    func tiltStickyLabel() {
        delayExecution(.now() + 0.1) { [self] in
            let dic:[UInt32:CGFloat] = [0:30, 1:-20, 2:20, 3:-25]
            let value = dic[arc4random_uniform(3)] ?? 18
            let transform = CGAffineTransform(rotationAngle: -CGFloat.pi/value)
            self.stickyLabel.transform = transform
            self.stickyLabelDeleteConfirmationLabel.transform = transform
        }
    }
}


extension PairCell {
    typealias Pan = UIPanGestureRecognizer
    typealias Tap = UITapGestureRecognizer
}

//ok
