//
//  MoreOptionsVC.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 08.12.2021.
//

import UIKit
import CoreData

class MoreOptionsVC:UIViewController {
    // MARK: - Data coming from CTTVC
    var indexPath:IndexPath?
    var initialColorName:String?
    var bubbleID:String?
    var timerReferenceClock:Float = -1
    var isTimer = false
    
    var showHideDurationButton_Title:String?
    var showHideDurationButton_Subtitle:String?
    
    // MARK: - properties
    var shouldButtonsStackBeHidden = false
    private var pulsatingRect:MoreOptionsColorRect?
    
    // MARK: - Outlets
    @IBOutlet var colorsRows: [UIStackView]!
    
    @IBOutlet weak var titleSymbol: TitleSymbol! {didSet{
        setupTitleSymbol()
        adaptUI()
    }}
    
    @IBOutlet var colorRects: [MoreOptionsColorRect]! {didSet{
        pulsatingRect =
        colorRects.filter { $0.currentTitle == initialColorName }.first
        
        delayExecution(.now() + 0.2) {[weak self] in
            self?.pulsatingRect?.pulsateAnimate(maximumScale: 1.6, duration: 3)
        }
    }}
    
    //timers only
    @IBOutlet weak var topButtonsStack: UIStackView! {didSet{
        topButtonsStack.isHidden = isTimer ? false : true
    }}
    
    @IBOutlet weak var showHideDurationButton: UIButton! {didSet{
        if isTimer {
            if #available(iOS 15.0, *) {
                showHideDurationButton.configuration?.title = showHideDurationButton_Title
                showHideDurationButton.configuration?.baseBackgroundColor = pulsatingRect?.fillColor
            } else {
                // Fallback on earlier versions
                showHideDurationButton.setTitle(showHideDurationButton_Title, for: .normal)
                showHideDurationButton.tintColor = pulsatingRect?.fillColor
            }
        }
    }}
    
    @IBOutlet weak var editDurationButton: UIButton! {didSet{
        editDurationButton.tintColor = pulsatingRect?.fillColor
    }}
    
    // MARK: - Actions
    @IBAction func toggleDuration(_ sender: UIButton) {
        let cttvc = (presentingViewController as! NavigationController).viewControllers.first as! CTTVC
        cttvc.toggleDuration(for: indexPath)
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func editDuration(_ sender:UIButton) {
        let navigationController = presentingViewController as? NavigationController
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let durationPickerVC = storyBoard.instantiateViewController(withIdentifier: "TimerDurationVC") as! DurationPickerVC
        
        //set here the payload for durationPickerVC
        durationPickerVC.payload = DurationPickerVC.Payload(timerOperation: .editDuration(pulsatingRect?.fillColor, bubbleID, timerReferenceClock, showHideDurationButton_Subtitle!))
        
        //presentingVC is NavigationController
        presentingViewController?.dismiss(animated: true)
        navigationController?.pushViewController(durationPickerVC, animated: true)
    }
    
    @IBAction func changeColor(_ button: UIButton) {
        guard let color = button.currentTitle else { return }
        
        UserFeedback.triggerSingleHaptic(.medium)
        button.scaleAnimate(random: false)
        
        let cttvc = (presentingViewController as! NavigationController).viewControllers.first as! CTTVC
        cttvc.changeColor(to:color, at:indexPath)
        presentingViewController?.dismiss(animated: true)
    }
        
    @IBAction func dismissVC(_ swipe: UISwipeGestureRecognizer) {
        if swipe.state == .ended {
            presentingViewController?.dismiss(animated: true)
        }
    }
    
    // MARK: - Methods
    private func registerFor_DidBecomeActive() {
        let name = UIApplication.didBecomeActiveNotification
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] notification in
            
            //when self back onscreen again, start pulsate animation once more
            if let onscreen = self?.view.isOnscreen, onscreen {
                self?.pulsatingRect?.pulsateAnimate(maximumScale:1.5, duration:3)
            }
        }
    }
    
    private func setupTitleSymbol() {
        titleSymbol.titleLabel.text = showHideDurationButton_Subtitle
        titleSymbol.titleLabel.textColor = pulsatingRect?.fillColor
        titleSymbol.symbol.tintColor = titleSymbol.titleLabel.textColor
        if !isTimer {titleSymbol.symbol.image = UIImage(systemName: "stopwatch")}
    }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        showHideDurationButton.setTitle(showHideDurationButton_Title, for: .normal)
        
        //custom VC transitions
        transitioningDelegate = self
        
        //fix animation stop when app back onscreen
        registerFor_DidBecomeActive()
    }
    deinit { NotificationCenter.default.removeObserver(self) }
}

// MARK: - Custom VC transition
extension MoreOptionsVC:UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimationController(slideDirection:.leftToRight, duration:0.7)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimationController(slideDirection:.rightToLeft)
    }
}

// MARK: - Trait collection
extension MoreOptionsVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            adaptUI()
        }
    }
    
    ///some views must look different when dark mode on/off
    private func adaptUI() {
        delayExecution(.now() + 0.1) {
            [weak self] in
            guard let self = self else { return }
            
            if self.initialColorName == "Charcoal" {
                self.titleSymbol.titleLabel.textColor = self.isDarkModeOn ? .white : .black
                self.titleSymbol.symbol.tintColor = self.titleSymbol.titleLabel.textColor
            }
        }
    }
}
