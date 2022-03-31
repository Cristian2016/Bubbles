/*1.why awakeFromNib does not get called?*/

import UIKit
import CoreData

extension PaletteVC {
    typealias UD = UserDefaults
    typealias Key = UD.Key
}

class PaletteVC: UIViewController {
    // MARK: - Public
    ///it will be hidden if the screen is not big enough. eg iPhone 7, 8 are not tall enough
    @IBOutlet weak var row0: UIStackView!
    @IBOutlet weak var rows: UIStackView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var containerView: UIView!
    
    public lazy var longPressedCircleColor = UIColor()
    
    @IBAction func circleTapped(_ circle:ColorCircle) {
        
        if let colorTitle = circle.currentTitle {
            
            createStopwatch(color: colorTitle)
            UserFeedback.triggerSingleHaptic(.medium)
        }
        navigationController?.popViewController(animated: true) /*dismiss to ChronoTimersTVC*/
    }
    
    @IBAction func circleLongPressed(_ gesture: LongPress) {
        /*make sure longpress occured within a circle*/
        guard let circle = (view.hitTest(gesture.location(in: view), with: nil) as? ColorCircle)
        else { return }
        
        if gesture.state == .began {
            longPressedCircleColor = circle.color
            UserFeedback.triggerDoubleHaptic(.medium)
            goToDurationPicker(from: circle)
        }
    }
    
    // MARK: - Private
    private func goToDurationPicker(from circle:ColorCircle) {
        performSegue(withIdentifier: Segue.toTimerDurationVC, sender: circle)
    }
    
    private func createStopwatch(color:String) {
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: EntityName.ct, in: AppDelegate.context) {
            let stopwatch = CT(entity: entityDescription, insertInto: AppDelegate.context)
            stopwatch.populate(color: color, kind: .stopwatch)
        }
        /* ⚠️ big problems if called without delay! */
        delayExecution(.now() + 0.1) {
            /* ⚠️ if delay is 0.01 timebubble will not deinit the moment the user swipe deletes. it will delete on next switch from palette to cttvc. why is that */
            CoreDataStack.shared.saveContext()
        }
    }
    
    // MARK: - used in InfoPictureProtocol
    private lazy var toggleAnimationButton:ToggleAnimationButton = {
        /* 🤔 can cause retain cycle? */
        let button = ToggleAnimationButton()
        button.addTarget(self, action: #selector(toggleAnimation(_:)), for: .touchUpInside)
        
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.numberOfLines = 3
        button.titleLabel?.textAlignment = .center
        button.setTitle(isAnimationOnAppearEnabled ?  "\nAnimation\nOFF" : "\nAnimation\nON", for: .normal)
        
        return button
    }()
    @objc func toggleAnimation(_ button:ToggleAnimationButton) {
        isAnimationOnAppearEnabled = !isAnimationOnAppearEnabled
        if isAnimationOnAppearEnabled {
            button.setTitle("\nAnimation\nOFF", for: .normal)
            animateCirclesOnAppear()
        } else {
            button.setTitle("\nAnimation\nON", for: .normal)
            animateCirclesOnAppear()
        }
    }
    
    // MARK: -  Overrides
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segue.toTimerDurationVC {/*toTimerDurationVC*/
            guard
                let durationPickerVC = segue.destination as? DurationPickerVC,
                let colorAsString = (sender as? ColorCircle)?.currentTitle
            else { fatalError() }
            
            durationPickerVC.payload = DurationPickerVC.Payload(timerOperation: .create(digitColor: longPressedCircleColor, digitColorAsString: colorAsString))
        }
    }
    
    override func viewDidLayoutSubviews() {        
        updateStackViewPositionAndAlpha_IfCurrentPhoneNotTallEnough()
    }
    
    var isAnimationOnAppearEnabled:Bool {
        get {
            if let value = UD.standard.value(forKey: Key.isAnimationOnAppearEnabled) as? Bool { return value }
            else { return true }
        }
        set { UD.standard.setValue(newValue, forKey: Key.isAnimationOnAppearEnabled) }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateCirclesOnAppear()
    }
    
    private func updateStackViewPositionAndAlpha_IfCurrentPhoneNotTallEnough() {
        if Device.currentPhoneNotTallEnough {
            self.row0.alpha = 0
            let newCenterY = (self.row0.frame.height)/2
            self.stackView?.transform = CGAffineTransform(translationX: 0, y: -newCenterY)
        }
    }
}

extension PaletteVC {
    func animateCirclesOnAppear() {
        if isAnimationOnAppearEnabled == true {
            rows.arrangedSubviews.forEach { row in
                row.subviews.shuffled().forEach { circle in
                    animateOnAppear(circle as UIView as! ColorCircle)
                }
            }
        } else {
            rows.arrangedSubviews.forEach { circle in
                circle.layer.removeAllAnimations()
            }
        }
    }
    private func animateOnAppear(_ circle:ColorCircle) {
    
        circle.scaleAnimate(random: true)
    }}

extension UIStackView {
    func randomlyMoveViewsToTop() {
        let randomIndex = Int(arc4random_uniform(UInt32(arrangedSubviews.count - 1)))
        bringSubviewToFront(arrangedSubviews[randomIndex])
    }
}

class ToggleAnimationButton: UIButton {
    override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(ovalIn: rect)
        UIColor.rgb(235, 38, 31).setFill()
        circlePath.fill()
    }
}


