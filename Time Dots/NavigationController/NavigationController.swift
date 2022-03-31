import UIKit

class NavigationController: UINavigationController {
    
    //do not let user exceed this limit!
    private let bubblesLimit = 15

    //do not allow if the user has 15 Time Bubbles already!
    private var shouldIAllowUserToGoToPallete = true
    
    override func awakeFromNib() {
        delegate = self //I use a delegate since I want custom VC transitions
    }
    
    // MARK: - outlets
    @IBOutlet weak var swipeRight_fromLeftEdge_Gesture:UIScreenEdgePanGestureRecognizer! {didSet{
//        view.addGestureRecognizer(swipeRight_fromLeftEdge_Gesture)
    }}
    @IBOutlet weak var swipeLeft_fromRightEdge_Gesture:UIScreenEdgePanGestureRecognizer! {didSet{
//        view.addGestureRecognizer(swipeLeft_fromRightEdge_Gesture)
    }}
    
    // MARK: - actions
    ///I think this action only brings up the PaletteVC and nothing else
    @IBAction func swipeRight_FromLeftEdge(_ gesture:UIScreenEdgePanGestureRecognizer?) {
        guard let gesture = gesture else {return}
        
        var fingerLocationXPercentComplete = gesture.location(in: gesture.view?.superview).x
        fingerLocationXPercentComplete /= topViewController!.view.frame.width
        let fingerSpeedX = gesture.velocity(in: gesture.view?.superview).x
        
        switch gesture.state {
        case .began:
            /*
             set interactiveTransition. must be reset back to nil when its job is done
             ⚠️ set interactiveTransition and then call performSegue. if you do it the other way around it will segue non-interactivelly
             */
            interactiveTransition = UIPercentDrivenInteractiveTransition()
            
            /*1.check which ViewController I'm currently in
             2.perform segue*/
            if let viewControllerID = topViewController?.restorationIdentifier {
                
                switch viewControllerID {
                case VC.chronoTimers:
                    guard
                        let cttvc = topViewController as? CTTVC,
                        let cttvcIsEmpty =
                            cttvc.frc.fetchedObjects?.isEmpty
                    else { return }
                    
                    if !cttvcIsEmpty {
                        let bubblesTotalCount = cttvc.frc.fetchedObjects!.count
                        shouldIAllowUserToGoToPallete = (bubblesTotalCount >= bubblesLimit) ? false : true
                    }
                    
                    if shouldIAllowUserToGoToPallete { cttvc.performSegue(withIdentifier: Segue.toPaletteVC, sender: nil) }
                    else {//15 time bubbles limit reached
                        
                        let alertImage = view.isDarkModeOn ? #imageLiteral(resourceName: "15limit inverted") : #imageLiteral(resourceName: "15limit")
                        let alertImageView = UIImageView(image: alertImage)
                        alertImageView.isUserInteractionEnabled = true
                        
                        let ratio = cttvc.view.frame.width / alertImage.size.width
                        let scale = ratio * 0.95
                        view.addSubviewInTheCenter(alertImageView)
                        
                        alertImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                        
                        let tap = UITapGestureRecognizer(target: self, action: #selector(removeAlertImagevIew(_:)))
                        alertImageView.addGestureRecognizer(tap)
                        
                        alertImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                        alertImageView.layer.shadowOpacity = 1
                        alertImageView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
                        
                        delayExecution(.now() + 4) {
                            alertImageView.removeFromSuperview()
                        }
                        
                        UserFeedback.triggerDoubleHaptic(.heavy)
                    }
                    
                default:break
                }
            }
            
        case .changed:
            if (fingerSpeedX > 1000) {
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.update(fingerLocationXPercentComplete)
            }
            
        case .cancelled, .ended:
            /*https://drive.google.com/file/d/1vi_DVA6spinKEfzB_433DzgupHPjytHk/view?usp=sharing
             if finger has travelled more than half the distance across the screen X axis,
             complete the animation, if not cancel it (go back to where it started)*/
            if (fingerLocationXPercentComplete >= 0.5) {
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.cancel()
            }
            interactiveTransition = nil
            
        default: break
        }
        
    }
    @IBAction func swipeLeft_FromRightEdge(_ gesture:UIScreenEdgePanGestureRecognizer) {
        var fingerLocationXPercentComplete = gesture.location(in: gesture.view?.superview).x
        fingerLocationXPercentComplete /= topViewController!.view.frame.width
        fingerLocationXPercentComplete = 1 - fingerLocationXPercentComplete
        let fingerSpeedX = gesture.velocity(in: gesture.view?.superview).x
        
        switch gesture.state {
        case .began:
            interactiveTransition = UIPercentDrivenInteractiveTransition()
            popViewController(animated: true)
            
        case .changed:
            if (fingerSpeedX <= -1000){
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.update(fingerLocationXPercentComplete)
            }
            
        case .cancelled, .ended:
            /*https://drive.google.com/file/d/1vi_DVA6spinKEfzB_433DzgupHPjytHk/view?usp=sharing
             if finger has travelled more than half the distance across the screen X axis,
             complete the animation, if not cancel it (go back to where it started)*/
            if fingerLocationXPercentComplete >= 0.5 { interactiveTransition?.finish() }
            else { interactiveTransition?.cancel() }
            interactiveTransition = nil
            
        default: break
        }
    }
    
    // MARK: - properties
    //interactive VC transition
    var interactiveTransition:UIPercentDrivenInteractiveTransition? /*
     1.set when gesture begins
     2.updated as finger keeps changing position
     3.reset when gesture ends*/
    
    private lazy var snapshotManager = SnapshotManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRightSwipeFromEdgeView()
        addLeftSwipeFromEdgeView()
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: -
    @objc func removeAlertImagevIew(_ sender:UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }
    
    // MARK: - Edge Swipe Replacement
    private lazy var rightSwipeViewWidth = UIScreen.main.bounds.width * 0.08
    private lazy var leftSwipeViewWidth = rightSwipeViewWidth
    
    private var rightSwipeView:UIView?
    private var leftSwipeView:UIView?
    
    private func addRightSwipeFromEdgeView() {
        rightSwipeView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: rightSwipeViewWidth, height: view.frame.height)))
        rightSwipeView?.isUserInteractionEnabled = true
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipeFromEdge(_:)))
        swipe.cancelsTouchesInView = false
        rightSwipeView?.addGestureRecognizer(swipe)
        rightSwipeView?.backgroundColor = .clear
        view.addSubview(rightSwipeView ?? UIView())
    }
    private func addLeftSwipeFromEdgeView() {
        let origin = CGPoint(x: view.frame.width - leftSwipeViewWidth, y: 0)
        leftSwipeView = UIView(frame: CGRect(origin: origin, size: CGSize(width: leftSwipeViewWidth, height: view.frame.height)))
        leftSwipeView?.isUserInteractionEnabled = true
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipeFromEdge(_:)))
        swipe.direction = .left
        swipe.cancelsTouchesInView = false
        leftSwipeView?.addGestureRecognizer(swipe)
        leftSwipeView?.backgroundColor = .clear
        view.addSubview(leftSwipeView ?? UIView())
    }
    
    @objc private func handleLeftSwipeFromEdge(_ gesture:UISwipeGestureRecognizer) {
        if gesture.state == .ended { popViewController(animated: true) }
    }
    @objc private func handleRightSwipeFromEdge(_ gesture:UISwipeGestureRecognizer) {
        if gesture.state == .ended {
            guard
                let cttvc = topViewController as? CTTVC
            else { return }
            
            let bubblesTotalCount = cttvc.frc.fetchedObjects!.count
            shouldIAllowUserToGoToPallete = (bubblesTotalCount >= bubblesLimit) ? false : true
            
            if shouldIAllowUserToGoToPallete { cttvc.performSegue(withIdentifier: Segue.toPaletteVC, sender: nil) }
            else {//15 time bubbles limit reached
                
                let alertImage = view.isDarkModeOn ? #imageLiteral(resourceName: "15limit inverted") : #imageLiteral(resourceName: "15limit")
                let alertImageView = UIImageView(image: alertImage)
                alertImageView.isUserInteractionEnabled = true
                
                let ratio = cttvc.view.frame.width / alertImage.size.width
                let scale = ratio * 0.95
                view.addSubviewInTheCenter(alertImageView)
                
                alertImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(removeAlertImagevIew(_:)))
                alertImageView.addGestureRecognizer(tap)
                
                alertImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                alertImageView.layer.shadowOpacity = 1
                alertImageView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
                
                delayExecution(.now() + 4) {
                    alertImageView.removeFromSuperview()
                }
                
                UserFeedback.triggerDoubleHaptic(.heavy)
            }
        }
    }
}

// MARK: - VC transitions
extension NavigationController:UINavigationControllerDelegate {
    /*animationController*/
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .push:
            return PushAnimator(with: snapshotManager)
        case .pop:
            return PopAnimator(with: snapshotManager)
        default:
            return nil
        }
    }
    
    /*interactionController*/
    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    /// use it to switch gestures on/off
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        /*control which gesture is allowed when in a certain VC*/
        switch viewController.restorationIdentifier {
        case VC.chronoTimers:
            /*
             1.can swipe right but you
             2.can't swipe left
             */
            /*you can only swipe right in this VCs*/
            swipeRight_fromLeftEdge_Gesture.isEnabled = true
            swipeLeft_fromRightEdge_Gesture.isEnabled = false
            
        case VC.palette: /*you can only swipe left when in Palette*/
            swipeLeft_fromRightEdge_Gesture.isEnabled = true
            swipeRight_fromLeftEdge_Gesture.isEnabled = false
            
        case VC.timerDuration: /*you can only swipe left when in DPicker*/
            swipeLeft_fromRightEdge_Gesture.isEnabled = true
            swipeRight_fromLeftEdge_Gesture.isEnabled = false
            
        default: break
        }
    }
}

// MARK: - keyboard hides when switching to Palette
extension NavigationController {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        leftSwipeView?.isUserInteractionEnabled = true
        rightSwipeView?.isUserInteractionEnabled = true
        
        switch viewController.restorationIdentifier {
        case ViewControllerID.paletteVC, ViewControllerID.timerDurationVC:
            (navigationController.viewControllers.first as? CTTVC)?.tableView.endEditing(true)
            rightSwipeView?.isUserInteractionEnabled = false
        case ViewControllerID.chronoTimersTVC:
            leftSwipeView?.isUserInteractionEnabled = false
        default: break
        }
    }
}

// MARK: - darkmode lightmode
extension NavigationController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            guard
                let vc = viewControllers.last,
                let fullyVisibleViewController = vc.restorationIdentifier
            else { fatalError("restoration identifier missing") }
            
            switch fullyVisibleViewController {
            case ViewControllerID.chronoTimersTVC:
                let cttvc = (vc as? CTTVC)
                cttvc?.tableView.visibleCells.forEach { ($0 as? CTCell)?.changeStickyAlpha()}
            case ViewControllerID.timerDurationVC:
                (vc as? DurationPickerVC)?.updateSpeechBubble()
            default: break
            }
        }
    }
}
