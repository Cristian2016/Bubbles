
import UIKit

class CTCell: UITableViewCell {
    typealias Animation = CABasicAnimation
    internal weak var delegate:ChronoTimerCellDelegate?
    
    //used to fix width being to big. Needs to be small enough for the undoSaveHint to be displayed properly
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint! {didSet{
        adaptStackHeightConstraint()
    }}
    
    @IBOutlet weak var stackView: UIStackView!
    
    // MARK: - adapt cell width
    ///on some devices there is not enough space for undoSaveHint view to be displayed properly
    private func adaptStackHeightConstraint() {
        delayExecution(.now() + 0.1) {
            guard let window = self.window else { print("no window, adapt my ass!"); return }
            
            let lateralSpace = (window.bounds.width - self.stackView.frame.width) / 2
                    
            if lateralSpace <= 10 {
                let value = self.dict[lateralSpace] ?? 11
                self.stackHeightConstraint.constant -= value
                self.layoutIfNeeded()
            }
        }
    }
    
    ///[lateralSpace:stackHeightConstraint.constant]
    let dict:[CGFloat:CGFloat] = [ /* 8 */1.5 : 8, /* iPodTouch */8 : 5, 10:5]
    
    // MARK: -
    //avoid font slightly wobbling left and right
//    private let font = UIFont.monospacedDigitSystemFont(ofSize: 50, weight: .regular)
    
    let startStickerRotationValues = [0:20, 1:-20, 2:25, 3:-25, 4:30, 5:-30, 6:35, 7:-35]
    let doneStickerRotationValues = [0:10, 1:-10, 2:15, 3:-15, 4:20, 5:-20, 6:12, 7:-12, 8:17, 9:-17]
    
    // MARK: - calendar stuff
    internal var nonCalendarColor:UIColor { isDarkModeOn ? #colorLiteral(red: 0.9976117015, green: 0.8907652497, blue: 0.4120309353, alpha: 1) : #colorLiteral(red: 0.9983770251, green: 0.8866510391, blue: 0.4181298018, alpha: 1).withAlphaComponent(1) }
    internal let calendarColor = #colorLiteral(red: 0.9984151721, green: 0.5134793993, blue: 0.4874061974, alpha: 1)
    
    // MARK: - outlets
    @IBOutlet weak var secondsButton:SecondsButton! {didSet{
        secondsButton.addGestureRecognizer(UILongPressGestureRecognizer())
    }}
    
    @IBOutlet weak var undoSaveHint: UIView!
    
    @IBOutlet weak var undoSaveHintTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hoursLabel: TimeComponentLabel! {didSet{
        setup_User_LongPressed_HoursLabel()
        
        //add double tap gesture to handle editDuration within CTTVC
        hoursLabel.addGestureRecognizer(doubleTap)
        
        //add left and right swipe gestures
        addGestureRecognizer(swipeLeft)
        addGestureRecognizer(swipeRight)
    }}
    
    //handles editDuration within CTTVC
    lazy var doubleTap:UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    lazy var swipeTranslation:CGFloat = frame.height
    
    lazy var swipeLeft:UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .left
        return gesture
    }()
    
    lazy var swipeRight:UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .right
        return gesture
    }()
    
    @IBOutlet weak var minutesLabel: TimeComponentLabel!
    
    @IBOutlet weak var startLine: UIView!
    
    @IBOutlet weak var doneLine: DoneLine!
    
    @IBOutlet weak var startSticker: SecondsSticker! {didSet{
        startSticker.kind = .startSticker
        startSticker.symbol.image = UIImage(named: "startSticker")
    }}
    
    @IBOutlet weak var doneSticker: SecondsSticker! {didSet{
        self.doneSticker.kind = .doneSticker
        doneSticker.symbol.image = UIImage(named: "doneStickerRound")
        UITweaks.rotateAtRandom(doneSticker, degreeValues: doneStickerRotationValues)
    }}
    
    @IBOutlet weak var stickyNote: StickyNote! {didSet{
        tiltStickyAtRandom()
        stickyNote.customize(outerColor: nonCalendarColor,
                             outerShape: .rectangle(cornerRadius: -0.005),
                             outerBorder: .thin,
                             innerColor: .clear,
                             innerShape: .rectangle(cornerRadius: -0.005),
                             innerBorder: .none,
                             slideDirection: .right(limit: 10))
        stickyNote.field.restorationIdentifier = "ctCell"
    }}
    
    @IBOutlet weak var calendarSticker: UIImageView!
    
    @IBOutlet weak var marble: Marble!
    
    @IBOutlet weak var durationHoursLabel: UILabel!
    @IBOutlet weak var durationMinutesLabel: UILabel!
    @IBOutlet weak var durationSecondsLabel: UILabel!
    
    // MARK: - Pause Sticker
    func hidePauseSticker(_ hide:Bool) {
//        secondsButton.hidePauseLine(hide)
        secondsButton.pauseSticker.alpha = hide ? 0 : 1
    }
    
    func coverTimeComponents(_ showCover:Bool) {
        hoursLabel.showCover(showCover, tricolor?.light)
        minutesLabel.showCover(showCover, tricolor?.medium)
        secondsButton.showCover(showCover, tricolor?.intense)
    }
    
    // MARK: -
    var tricolor:TricolorProvider.Tricolor? {didSet{
        hoursLabel.color = tricolor?.light ?? .black
        minutesLabel.color = tricolor?.medium ?? .black
        secondsButton.color = tricolor?.intense ?? .black
        
        hoursLabel.setNeedsDisplay()
        minutesLabel.setNeedsDisplay()
        secondsButton.setNeedsDisplay()
    }}
    
    func invisibleHoursLabel(_ invisible:Bool) {
        if hoursLabel.color == .clear && secondsButton.currentTitleColor == .clear { return }
                
        hoursLabel.color = invisible ? .clear : tricolor?.light ?? .green
        hoursLabel.alpha = invisible ? CGFloat(0.011) : 1.0
        hoursLabel.textColor = invisible ? .clear : .white
    }
    
    //when user enters sticky note in the CTTVC
    var  checkSticky = false {didSet{
        var text = stickyNote.field.text ?? String.empty
        
        //must get rid of accidental white spaces ex.: " Gym "
        text.trimWhiteSpaceAtTheBeginning()
        text.trimWhiteSpaceAtTheEnd()
        
        delegate?.userResignedFirstResponder(cellIndex: secondsButton.tag, fieldText: text)
        checkSticky = false
    }}
    
    func setupCalendarSticker(for ct:CT, animated:Bool) {
        calendarSticker.alpha = 0.0
        
        switch ct.stickyNoteVisible {
        case true:
            if ct._isCalendarEnabled {
                if case ct._calendarStickerState = CT.CalendarStickerState.minimized {
                    calendarSticker.alpha = 0.0
                } else {
                    //set it back to 1.0 and it will stay visible behind the sticker
                    calendarSticker.alpha = 0.0 //keep calendar sticker hidden
                }
                UIView.animate(withDuration: animated ? 1.0 : 0.0) {[weak self] in
                    self?.calendarSticker.transform = CGAffineTransform(translationX: 60, y: -6)
                }
            }
            
        default:
            switch ct._calendarStickerState {
            case .hidden: break
            case .minimized:
                calendarSticker.alpha = 1.0
                delayExecution(.now() + 0.1) {
                    [weak self] in
                    guard let self = self else { return }
                    
                    let width = self.calendarSticker.frame.size.width
                    UIView.animate(withDuration: animated ? 1.0 : 0.0) {[weak self] in
                        self?.calendarSticker.transform = CGAffineTransform(translationX: -width * 2/3, y: 0)
                    }
                }
                
            case .fullyDisplayed:
                calendarSticker.alpha = 1.0
                UIView.animate(withDuration: animated ? 1.0 : 0.0) {[weak self] in
                    self?.calendarSticker.transform = .identity
                }
                
            case .behindStickyNote: break
            }
        }
    }
    
    // MARK: - dark mode
    func changeStickyAlpha() {
        if stickyNote.slidingBackground.color != calendarColor {
            stickyNote.slidingBackground.color = nonCalendarColor
        }
    }
    
    //use it to prevent square cell to change shape continuously
    private var squareHasBeenRandomlyOffsetAlready = false
        
    private(set) var fiveSecondsTimer:Timer?
        
    func showUndoSaveHint(_ show:Bool) {
        if show {
            //show undosave
            //translateX by -10
            undoSaveHint.isHidden = false
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
                [weak self] in
                self?.undoSaveHint.transform = CGAffineTransform(translationX: -10, y: 0)
            } completion: { _ in
                if self.fiveSecondsTimer != nil {
                    self.fiveSecondsTimer?.invalidate()
                    self.fiveSecondsTimer = nil
                }
                self.fiveSecondsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                    
                    UIView.animate(withDuration: 0.2, delay: 0, options: []) {[weak self] in
                        self?.undoSaveHint.transform = .identity
                    } completion: { _ in
                        self.undoSaveHint.isHidden = true
                    }
                })
            }
        }
        else {
            undoSaveHint.isHidden = true
            undoSaveHint.transform = .identity
        }
    }
}

// MARK: - marble stuff
extension CTCell:CAAnimationDelegate {
    
    enum MarbleCommand {
        case identity
        case start (_ duration:TimeInterval, _ angle:CGFloat)
        case stop (_ angle:CGFloat)
    }
    
    func marbleRotation(_ command:MarbleCommand) {
        switch command {
        case .start(let duration, let angle):
            startMarbleRotation(with: duration, from: angle)
            
        case .stop(let angle):
            stopMarbleRotation(at: angle)
            
        case .identity:
            stopMarbleRotation(at: 0)
            marble.transform = .identity
        }
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch flag {
        case true: /* animation finished by itself */
            delegate?.animationStopped(cellIndex: secondsButton.tag, flag: true)
            
        case false: /* animation removed from the layer before finishing */
            delegate?.animationStopped(cellIndex: secondsButton.tag, flag: false)
        }
    }
    
    //make sure before you add any animation that there is no other running already
    private func startMarbleRotation(with duration:TimeInterval, from angle:CGFloat) {
        
        let noMarbleAnimation = marble.layer.animation(forKey: "360") == nil
        guard noMarbleAnimation else { return }
        
        self.marble.layer.add(Animation.rotate360(duration, startAngle: angle, delegate: self), forKey: "360")
    }
    
    ///1.remove animations 2.CGAffineTransform(rotationAngle: angle)
    ///if angle zero, it means marble goes back to its identity value
    private func stopMarbleRotation(at angle:CGFloat) {
        marble.layer.removeAllAnimations()
        if angle == 0 { delayExecution(.now() + 0.1) {
            [weak self] in
            self?.marble.transform = .identity
        } }
        else { marble.transform = CGAffineTransform(rotationAngle: angle) }
    }
}

protocol ChronoTimerCellDelegate:AnyObject {
    
    func animationStopped(cellIndex index:Int, flag:Bool)
    
    ///time to create a sticky note
    func userResignedFirstResponder(cellIndex index:Int, fieldText:String)
    
    func hoursLabelPressed(cellIndex index:Int)
    
    func calendarStickerTapped(cellIndex index:Int)
    
    func undoLastActionTapped(_ button:UIButton)
}

// MARK: - stickies
extension CTCell {
    
    func tiltStickyAtRandom() {
        let /* hours */ height = hoursLabel.frame.height
        let yPercentage = CGFloat(0.046)
        
        let dic:[UInt32:CGFloat] = [0:40, 1:35, 2:30, 3:45, 4:-45, 5:-50, 6:50, 7:-55, 8:55 ]
        let value = dic[arc4random_uniform(UInt32(dic.count))] ?? 18
        stickyNote.transform = CGAffineTransform(translationX: 200, y: height * yPercentage)
        stickyNote.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/value)
    }
    
    private func setup_User_LongPressed_HoursLabel() {
        
        let longPress = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(hideShowStickyNote(sender:)))
        hoursLabel.addGestureRecognizer(longPress)
    }
    
    @objc func hideShowStickyNote(sender:UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.hoursLabelPressed(cellIndex: secondsButton.tag)
        }
    }
}

// MARK: - helpers
extension CTCell {
    func hide(_ isHidden:Bool, _ subview:UIView?, scaleAnimate:Bool = false) {
        guard let subview = subview else {return}
        
        subview.alpha = isHidden ? 0 : 1
        if scaleAnimate {
            UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: []) {
                [weak self] in
                subview.transform = CGAffineTransform(scaleX: isHidden ? 0.0 : 1.0, y: isHidden ? 0.0 : 1.0)
                self?.tiltStickyAtRandom()
            }
        }
        
//        if subview.restorationIdentifier == "doneLine" {
//            self.coverTimeComponents(isHidden ? false : true)
//        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetAlphas()
    }
    
    private func resetAlphas() {
        marble.alpha = 0
        
        stickyNote.alpha = 0
        minutesLabel.alpha = 0
        invisibleHoursLabel(true)
        
        durationHoursLabel.alpha = 0
        durationMinutesLabel.alpha = 0
        durationSecondsLabel.alpha = 0
        
        //put time components in the usual order
        if hoursLabel.layer.zPosition == 2 {
            hoursLabel.layer.zPosition = 0
            minutesLabel.layer.zPosition = 0
        }
    }
}

// MARK: - calendarSticker
extension CTCell {
    @objc func calendarStickerTapped(_ sender:UITapGestureRecognizer) {
        delegate?.calendarStickerTapped(cellIndex: secondsButton.tag)
    }
}

// MARK: - widget stuff
extension CTCell {
    func shapeShift(_ kind:ShapeShifterKind) {
        
        //if kind square and cell is square already no need to change to square again
        if case ShapeShifterKind.square(radius: _) = kind {
            if case ShapeShifterKind.square(radius: _) = secondsButton.kind {
                return
            }
        }
        
        secondsButton.kind = kind
        minutesLabel.kind = kind
        hoursLabel.kind = kind
        
        switch kind {
        case .circle:
            minutesLabel.transform = .identity
        default:
            if !squareHasBeenRandomlyOffsetAlready {
                delayExecution(.now() + 0.3) {
                    [weak self] in
                    UIView.animate(withDuration: 0.5) {
                        self?.minutesLabel.transform = CGAffineTransform(translationX: 0, y: self?.randomOffset() ?? -2)
                    }
                }
                squareHasBeenRandomlyOffsetAlready = true
            }
        }
    }
    
    private func randomOffset() -> CGFloat { CGFloat.random(in: -6...6) }
}

//fixes an annoting accidental cell selection when user scolls in the tableView
extension CTCell {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        selectionStyle = .none
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectionStyle = .gray
    }
}
