// troubleshooting https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/TroubleshootingCoreData.html
//https://stackoverflow.com/questions/12622424/how-do-i-animate-constraint-changes/12664093#12664093

//perform

import UIKit
import CoreData

extension EditDurationVC {
    typealias LongPress = UILongPressGestureRecognizer
    
    typealias Swipe = UISwipeGestureRecognizer
    typealias Tap = UITapGestureRecognizer
    typealias FRC = NSFetchedResultsController<TimerDuration>
    typealias TV = UITableView
    typealias PV = UIPickerView
    
    typealias MenuConfiguration = UIContextMenuConfiguration
    typealias MenuInteraction = UIContextMenuInteraction
    typealias Action = UIAction
    typealias Menu = UIMenu
}

class EditDurationVC: UIViewController, SlotsManagerDelegate, FlippingBackground {
    
    @IBOutlet weak var titleSymbol: TitleSymbol! {didSet{
        titleSymbol.titleLabel.font = .systemFont(ofSize: 28, weight: .medium)
        titleSymbol.titleLabel.text = "Recents"
        titleSymbol.symbol.image = UIImage(systemName: "clock")
        
        titleSymbol.titleLabel.textColor = colorsDict[okButtonColor] ?? .black
        titleSymbol.symbol.tintColor = colorsDict[okButtonColor] ?? .black
    }}
    
    //user tap hold and can delete any row
    @IBOutlet weak var titleStack: UIStackView! {didSet{
        let tapHold = LongPress(target: self, action: #selector(handle(_:)))
        
        let doubleTap:Tap = {
            let gesture = Tap(target: self, action: #selector(handle(_:)))
            gesture.numberOfTapsRequired = 2
            return gesture
        }()
        
        titleStack.addGestureRecognizer(tapHold)
        titleStack.addGestureRecognizer(doubleTap)
    }}
    
    @IBOutlet weak var threeDotsTop: UILabel!{didSet{
        threeDotsTop.textColor = colorsDict[self.okButtonColor] ?? .black
    }}
    
    @IBOutlet weak var threeDotsBottom: UILabel! {didSet{
        threeDotsBottom.textColor = colorsDict[self.okButtonColor] ?? .black
    }}
    
    internal var isTopVisible = true
    
    var shouldShow3Dots:Bool {
        fetchedResultsController.fetchedObjects!.count > 4
    }
    
    @objc
    private func handle(_ gesture:UIGestureRecognizer) {
        if gesture.isKind(of: LongPress.self) {
            if gesture.state == .began { toggleDeleteMode() }
        } else {
            if gesture.state == .ended { toggleDeleteMode() }
        }
    }
    
    private func toggleDeleteMode() {
        UserFeedback.triggerSingleHaptic(.soft)
        table.isEditing = !table.isEditing
        performDeleteModeAnimation(table.isEditing)
    }
    
    // MARK: - ANIMATIONS 🔸 Delete Mode
    private func performDeleteModeAnimation(_ isEditing:Bool) {
        deleteModeAnimator = table.isEditing ? enterDeleteModeAnimator : exitDeleteModeAnimator
        
        view.layoutIfNeeded() //①
        deleteModeAnimator.startAnimation()
    }
        
    //set either to 1 enterDeleteModeAnimator or 2 exitDeleteModeAnimator
    private var deleteModeAnimator:UIViewPropertyAnimator!
    
    //1
    private var enterDeleteModeAnimator:UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.2)
        animator.addAnimations {
            [weak self] in
            guard let self = self else { return }
            
            let translationY:CGFloat = self.isContainerBelowEditedCell ? 10 : -10
            self.container.transform = CGAffineTransform(translationX: 0, y: translationY)
            
            let scaleValue = self.backgroundScaleUpValue
            self.background.transform = CGAffineTransform(scaleX: scaleValue, y: scaleValue)

            //animateWidth constraint
            self.tableWidthConstraint.constant *= scaleValue //②
            self.view.layoutIfNeeded() //③
        }
        
        animator.addCompletion { [weak self] _ in
            self?.deleteModeAnimator = nil
        }
                
        return animator
    }
    //2
    private var exitDeleteModeAnimator:UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.15)
        animator.addAnimations {
            [weak self] in
            guard let self = self else { return }
            
            self.container.transform = .identity
            self.background.transform = .identity

            //animateWidth constraint
            self.tableWidthConstraint.constant = 168 //②
            self.view.layoutIfNeeded() //③
        }
        
        animator.addCompletion { [weak self] _ in
            self?.deleteModeAnimator = nil
        }
                
        return animator
    }
    
    //fucking constraint does not want to animate in reverse!
    @IBOutlet weak var tableWidthConstraint: NSLayoutConstraint!
    
    // MARK: - FLIP GESTURES 🔸 Table and OKButton
    private enum TableFlipKind {
        case toOk //from tableBackground to okButton
        case fromOk //buton to tableBackground
    }
    
    // MARK: Outlet
    //it contains 3: tableBackground table and okButton
    @IBOutlet weak var container: UIView! {didSet{ setupContainer_FlipGestures() }}
    
    //@IBOutlet okButton
    
    // MARK: Methods
    ///flips table and tableBackground
    @objc private func flip_BackgroundToOk(_ gesture:Swipe) {
        if gesture.state == .ended {
            let option:UIView.AnimationOptions
            
            switch gesture.direction {
            case .down:
                option = .transitionFlipFromBottom
            case .up:
                option = .transitionFlipFromTop
            case .right:
                option = .transitionFlipFromLeft
            case .left:
                option = .transitionFlipFromRight
            default:
                option = .transitionFlipFromRight
            }
            
            flipTable(.toOk)
            flip(from: background, to: okButton, durationForEach: 0.4, option: [option, .showHideTransitionViews])
        }
    }
    
    ///flips table and OkButton
    @objc private func flip_OkToBackground(_ gesture:Swipe) {
        let option:UIView.AnimationOptions
        
        if gesture.state == .ended {
            switch gesture.direction {
            case .down: option = .transitionFlipFromBottom
            case .up: option = .transitionFlipFromTop
            case .left: option = .transitionFlipFromRight
            case .right: option = .transitionFlipFromLeft
            default: option = .transitionFlipFromLeft
            }
            
            flipTable(.fromOk)
            flip(from: okButton, to: background, durationForEach: 0.4, option: [option, .showHideTransitionViews])
        }
    }
    
    ///flips table only
    private func flipTable(_ flipKind:TableFlipKind) {
        let option: UIView.AnimationOptions
        let animation:()->()
        let duration:TimeInterval
        
        switch flipKind {
        case .toOk:
            option = .transitionFlipFromTop
            animation = {
                [weak self] in
                self?.table.alpha = 0
            }
            duration = 0.3
            
        case .fromOk:
            option = randomFlipAnimation()
            animation = {
                [weak self] in
                self?.table.alpha = 1
            }
            duration = 0.8
        }
        
        /* 0︎⃣ */UIView.transition(with: table, duration: duration, options: [option,.showHideTransitionViews, .allowUserInteraction]) { animation() }
    }
    
    private func flip(from fromView:UIView, to toView:UIView, durationForEach:TimeInterval, option:UIView.AnimationOptions) {
        
        UserFeedback.triggerSingleHaptic(.light)
        
        if fromView === self.okButton {
            self.okButton.layer.removeAllAnimations()
        }
        
        UIView.transition(with: fromView, duration: durationForEach, options: [option, .showHideTransitionViews]) {
            fromView.alpha = 0
        }
        
        UIView.transition(with: toView, duration: durationForEach, options: [option, .showHideTransitionViews]) {
            
            toView.alpha = 1 //animation
            
        } completion: {[weak self] _ in
            guard let self = self else { return }
            if toView === self.okButton {
                delayExecution(.now() + 0.3) { self.okButton.pulsateAnimate() }
            }
        }
    }
    
    // MARK: Helpers and initial setup
    private func randomFlipAnimation() -> UIView.AnimationOptions {
        let options:[UIView.AnimationOptions] = [.transitionFlipFromTop,
                                                 .transitionFlipFromBottom,
                                                 .transitionFlipFromLeft,
                                                 .transitionFlipFromRight]
        return  options.randomElement() ?? .transitionFlipFromTop
    }
    
    ///4 flipGestures. flips table and tableBackground
    internal func setupContainer_FlipGestures() {
        let flipTableAndBackground = #selector(flip_BackgroundToOk(_:))
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: flipTableAndBackground)
        swipeDown.direction = .down
        container.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: flipTableAndBackground)
        swipeUp.direction = .up
        container.addGestureRecognizer(swipeUp)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: flipTableAndBackground)
        swipeLeft.direction = .left
        container.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: flipTableAndBackground)
        swipeRight.direction = .right
        container.addGestureRecognizer(swipeRight)
    }
    
    private func setupOkButton_FlipGestures() {
        let flipTableAndOkButton = #selector(flip_OkToBackground(_:))
        
        okButton.swipeUp.addTarget(self, action: flipTableAndOkButton)
        okButton.swipeDown.addTarget(self, action: flipTableAndOkButton)
        okButton.swipeLeft.addTarget(self, action: flipTableAndOkButton)
        okButton.swipeRight.addTarget(self, action: flipTableAndOkButton)
    }
    
    // MARK: -
    @IBOutlet weak var arrowImages: UIStackView!
    
    @IBOutlet weak var hmsLabel: HMSHeader! {didSet{
        hmsLabel.stackView.subviews.forEach {
            let label = $0 as? UILabel
            label?.textColor = colorsDict[okButtonColor] ?? .black
        }
    }}
    
    private let cellReuseIdentifier = "durationCell"
    
    private let rowsPerPage = 5
    
    private let headerHeight = CGFloat(50.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slotsManager.delegate = self
        
        table.dataSource = diffableDataSource
        table.delegate = self
        
        //diffable data source and fetched results controller
        setFetchedResultsController()
        setDiffableDataSource()
        
        if fetchedResultsController.fetchedObjects == nil { try? fetchedResultsController.performFetch() }
    }
    
    // MARK: - Methods
    private func futureRow(for currentRow:Int, _ pickerKind:ID) -> Int {
        var futureRow = currentRow
        
        switch pickerKind {
        case .hr:
            if [0,2].contains(currentRow/hoursRange.count) {
                futureRow = currentRow%hoursRange.count + hoursRange.count
            }
            
        case .min:
            if [0,2].contains(currentRow/minutesRange.count) {
                futureRow = currentRow%minutesRange.count + minutesRange.count
            }
            
        case .sec:
            if [0,2].contains(currentRow/secondsRange.count) {
                futureRow = currentRow%secondsRange.count + secondsRange.count
            }
        }
        return futureRow
    }
    
    ///user thinks  wheels move "circular", but they are not! there are 3 repetitive ranges for hr min sec. default position of each wheel should be on the middle range
    private func makeSureWheelsCanMoveCircular(_ animated:Bool = false) {
        pickers.forEach {
            let selectedRow = $0.selectedRow(inComponent: 0)
            
            let newRow:Int
            
            switch $0.restorationIdentifier! {
            case ID.hr.rawValue:
                newRow = futureRow(for: selectedRow, ID.hr)
                
            case ID.min.rawValue:
                newRow = futureRow(for: selectedRow, ID.min)
                
            case ID.sec.rawValue:
                newRow = futureRow(for: selectedRow, ID.sec)
                
            default:
                newRow = 0  /* some shit ass value :))) */
            }
            
            $0.selectRow(newRow, inComponent: 0, animated: animated)
        }
    }
    
    @objc
    private func dismissSelf() {
        //revert colors for seconds minutes hours on CTTVC.cell back to white
        let cttvc = (presentingViewController as? NavigationController)?.viewControllers.first as? CTTVC
        cttvc?.prepareCellToExitEditMode()
        
        timer = nil //⚠️ remove any reference to timer otherwise it will not be removed from memory and will be turned an "empty shell"
        
        //dimiss EditDurationVC
        presentingViewController?.dismiss(animated: false)
    }
    
    // MARK: - Properties
    //2. wheels
    private let hoursRange = CountableRange(0...48)
    private let minutesRange = CountableRange(0...59)
    private let secondsRange = CountableRange(0...59)
    
    private let colorsDict:[UIColor:UIColor] = [.charcoal : .white, .chocolate :.white]
    
    @IBOutlet weak var maxDurationsImageView: UIImageView!
    
    @IBOutlet weak var emptyListMessage: UITextView!
    
    @IBOutlet var pickers: [PV]! {didSet{ changeWheelSelectionViewLook() }}
    
    @IBOutlet weak var table: TV!
    
    @IBOutlet weak var background: TableBackground! {didSet{ background.color = okButtonColor }}
    
    // MARK: 🔻 Diffable Data Source
    enum Section {
        case main
    }
    
    private var diffableDataSource:DDS!
    
    private func setDiffableDataSource() {
        diffableDataSource = DDS(tableView: table) {
            [weak self] table, indexPath, item in
                        
            guard
            let self = self,
            let cell = table.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as? DurationCell
            else { return UITableViewCell() }
            
            cell.configureLabels(duration: item.duration)
            
            let textColor = self.colorsDict[self.okButtonColor] ?? .black
            cell.minLabel.textColor = textColor
            cell.secLabel.textColor = textColor
            cell.hrLabel.textColor = textColor
                        
            return cell
        }
    }
    
    private(set) var fetchedResultsController:FRC!
    
    private func setFetchedResultsController() {
        let request:NSFetchRequest = TimerDuration.fetchRequest()
        
        let predicate =
        NSPredicate(format: "%K == %@", #keyPath(TimerDuration.timer), timer)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        
        request.sortDescriptors = [sortDescriptor]
        request.predicate = predicate
        
        let context = AppDelegate.context
        fetchedResultsController = FRC(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
    }
    
    // MARK: 🔻 Payload from CTTVC
    //3
    var centers:CTTVC.TimeComponentsCenters!
    var cellFrame:CGRect!
    var cellIndexPath:IndexPath!
    
    //4. show current clock first
    var initialSeconds:String!
    var initialMinutes:String!
    var initialHours:String!
    
    var referenceClock:Float!
    var timerID:String! //remove reference to object on  dismissSelf
    
    //if I pass the timer in the prepareForSegue, it does not deinit. So I have to search in storage for the timer
    lazy var timer:CT! = {
        let request:NSFetchRequest = CT.fetchRequest()
        let bubbles = try! AppDelegate.context.fetch(request)
        return bubbles.filter { $0.id?.uuidString == timerID }.first!
    }()
    
    var okButtonStringColor:String?
    var okButtonColor:UIColor!
    var hoursLabelColor:UIColor!
    
    // MARK: 🔻 Overrides
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //pickers
        setInitialPickerValues()
        setupPickerMetrics()
        setupPickerUnderlabels()
        
        delayExecution(.now() + 0.05) { self.positionContainer() }
    }
    
    // MARK: 🔻 Slots Manager
    private lazy var slotsManager = SlotsManager(.edit(referenceClock))
    
    internal var slots = [Int]() {didSet{
        switch slotsManager.state {
        case .spins(_):
            //only if okButton not visible yet
            if okButton.alpha == 0 {
                flip(from: background, to: okButton, durationForEach: 0.3, option: randomFlipAnimation())
            }
            
            //maxDuration 48Hr. make sure all wheels match "48_00_00"
            if slots.count > 1, slots[0...1] == [4,8] {
                pickers.forEach {
                    let isMinutes = $0.restorationIdentifier == ID.min.rawValue
                    let isSeconds = $0.restorationIdentifier == ID.sec.rawValue
                    
                    if  isMinutes || isSeconds {
                        if $0.selectedRow(inComponent: 0) != 0 {
                            //instead of selecting zero in row 0, select zero in row count
                            $0.selectRow(minutesRange.count, inComponent: 0, animated: true)
                        }
                    }
                }
            }
            
            //00_00_00 combination is not allowed
            if slotsManager.isCombinationForbidden {
                let seconds = pickers.filter { $0.restorationIdentifier == ID.sec.rawValue }.first
                seconds?.selectRow(1 + secondsRange.count, inComponent: 0, animated: true)
            }
            
            delayExecution(.now() + 0.3) {[weak self] in
                self?.makeSureWheelsCanMoveCircular()
            }
            
        default: break
        }
    }}
    
    // MARK: 🔻 Other
    private var okButtonExtraTextShowCount:Int {
        get {
            let key = UserDefaults.Info.editDurationVC_ShowExtraText.rawValue
            let value = UserDefaults.standard.integer(forKey: key)
            return value
        }
        
        set {
            let key = UserDefaults.Info.editDurationVC_ShowExtraText.rawValue
            var value = UserDefaults.standard.integer(forKey: key)
            value += 1 //increase value. when value 3 extratext will not be swown anymore
            UserDefaults.standard.set(value, forKey: UserDefaults.Info.editDurationVC_ShowExtraText.rawValue)
        }
    }
    
    @IBOutlet weak var okButton: OkButton1! {didSet{
        okButton.alpha = 0
        okButton.color = okButtonColor
        
        okButton.arrowUp.tintColor = hoursLabelColor
        okButton.arrowLeft.tintColor = hoursLabelColor
        
        setupOkButton_FlipGestures()
        okButton.tap.addTarget(self, action: #selector(okButtonTapped(_:)))
    }}
    
    internal var isContainerBelowEditedCell:Bool!
    
    internal let backgroundScaleUpValue = CGFloat(1.1)
        
    @IBOutlet weak var containerCenterYAnchor: NSLayoutConstraint!
    
    @objc
    func okButtonTapped(_ tap:Tap) {
        let touchPoint = tap.location(in: okButton)
        if !okButton.okCircle.circlePath.contains(touchPoint) {
            dismissSelf()
            return
        }
        okButtonExtraTextShowCount += 1
        let newReferenceClock /* from slots */ = slotsManager.slotsToReferenceClock
        let cttvc =
        (presentingViewController as? NavigationController)?.viewControllers.first as? CTTVC
        
        //replace old with new duration
        cttvc?.replaceInTimer(newReferenceClock, timer.id?.uuidString)
        
        dismissSelf()
    }
    
    ///restoration identifier
    private enum ID:String {
        case hr
        case min
        case sec
    }
    
    private func changeWheelSelectionViewLook() {
        //hide selection view background and make black contour instead
        delayExecution(.now() + 0.05) {[weak self] in
            guard let self = self else { return }
            
            let /* border */color = self.colorsDict[self.okButtonColor] ?? .black
            self.pickers.forEach { $0.changeSelectionViewLook(borderColor:color) }
        }
    }
    
    private func setupPickerMetrics() {
        //center wheels over time components of the cell and set wheels to correct duration
        pickers.forEach {
            //0. set size
            let width = cellFrame.size.width / 3.2
            $0.frame.size = CGSize(width: width, height: width * 1.2)
            
            //1. disable autolayout system
            $0.translatesAutoresizingMaskIntoConstraints = true
            
            //2. position centers
            switch $0.restorationIdentifier! {
            case ID.hr.rawValue: $0.center = centers.hours
            case ID.min.rawValue: $0.center = centers.minutes
            case ID.sec.rawValue: $0.center = centers.seconds
            default: break
            }
        }
    }
    
    //on viewWillAppear
    private func setInitialPickerValues() {
        pickers.forEach {
            switch $0.restorationIdentifier! {
            case ID.sec.rawValue:
                $0.selectRow(Int(initialSeconds)! + secondsRange.count, inComponent: 0, animated: false)
            case ID.min.rawValue:
                $0.selectRow(Int(initialMinutes)! + minutesRange.count, inComponent: 0, animated: false)
            case ID.hr.rawValue:
                $0.selectRow(Int(initialHours)! + hoursRange.count, inComponent: 0, animated: false)
            default: break
            }
        }
    }
    
    //hr min sec under wheels
    private func setupPickerUnderlabels() {
        pickers.forEach {
            let underlabel = underlabel(for: $0.restorationIdentifier)
            $0.addSubviewInTheCenter(underlabel)
            let yOffset = cellFrame.height * 0.35
            underlabel.transform = CGAffineTransform(translationX: 0, y: yOffset)
        }
    }
    
    private func underlabel(for restorationID:String?) -> UILabel {
        guard let restorationID = restorationID else { fatalError() }
        
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        
        let text:String
        
        switch restorationID {
        case ID.hr.rawValue: text = "hr"
        case ID.min.rawValue: text = "min"
        case ID.sec.rawValue: text = "sec"
        default: text = ID.sec.rawValue
        }
        
        label.text = text
        label.textAlignment = .center
        
        let darkColors = [UIColor.charcoal, .chocolate]
        label.textColor = darkColors.contains(okButtonColor) ? .white : .black
        
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return label
    }
    
    private var okButtonShown = false
}

// MARK: - Picker view Data Source
extension EditDurationVC:UIPickerViewDataSource {
    func numberOfComponents(in pickerView: PV) -> Int { 1 }
    
    func pickerView(_ pickerView: PV, numberOfRowsInComponent component: Int) -> Int {
        let value:Int
        switch pickerView.restorationIdentifier! {
        case ID.hr.rawValue: value = hoursRange.count
        case ID.min.rawValue: value = minutesRange.count
        case ID.sec.rawValue: value = secondsRange.count
        default: value = secondsRange.count
        }
        
        //        value * 2 to make it circular
        return value * 3
    }
}

// MARK: - Picker view Delegate
extension EditDurationVC:UIPickerViewDelegate {
    
    func pickerView(_ pickerView: PV, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        return label(for:pickerView, and:row)
    }
    
    func pickerView(_ pickerView: PV, rowHeightForComponent component: Int) -> CGFloat { cellFrame.height * 0.54 }
    
    func pickerView(_ pickerView: PV, didSelectRow row: Int, inComponent component: Int) {
        
        //⚠️ only Model updates! UI updates under slots property
        
        //replace in the slotsArray an old pair with a new pair
        //ex: replace [1,2] with [6, 6] in [1,2, 3,4,5,8] -> [6,6, 3,4,5,8]
        let newPair:ArraySlice<Int>
        var oldPair:ArraySlice<Int>
        
        //digitsSlots array is changed each time the user makes a new selection
        switch pickerView.restorationIdentifier! {
        case ID.hr.rawValue:
            slotsManager.state = .spins(.hours)
            
            newPair = digitsPair(from: hoursRange[row%49])
            oldPair = slots[0...1]
            if oldPair != newPair {
                slotsManager.replace(.hours, with: hoursRange[row%49])
            }
            
        case ID.min.rawValue:
            slotsManager.state = .spins(.minutes)
            
            newPair = digitsPair(from: minutesRange[row%60])
            oldPair = slots[2...3]
            if oldPair != newPair {
                slotsManager.replace(.minutes, with: minutesRange[row%60])
            }
            
        case ID.sec.rawValue:
            slotsManager.state = .spins(.seconds)
            
            newPair = digitsPair(from: secondsRange[row%60])
            oldPair = slots[4...5]
            if oldPair != newPair {
                slotsManager.replace(.seconds, with: secondsRange[row%60])
            }
            
        default: break
        }
        
        //exception maxDuration 48Hr
        if slots.count > 1 && slots[0...1] == [4,8] {
            slotsManager.slots = [4,8,0,0,0,0]
        }
        
        //exception 00_00_00
        if slotsManager.isCombinationForbidden {
            slotsManager.slots = [0,0,0,0,0,1]
        }
    }
    
    // MARK: - Little Helpers
    private func digitsPair(from number:Int) -> ArraySlice<Int> {
        [number/10, number%10]
    }
    
    // FIXME: keeps making new labels instead of using what is already has
    func label(for pickerView:PV, and row:Int) -> UILabel {
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 80, height: 80)))
        
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 50, weight: .regular)
        
        let digitColor = colorsDict[okButtonColor] ?? .black
        label.textColor = digitColor
        
        switch pickerView.restorationIdentifier! {
        case ID.hr.rawValue: label.text = String(hoursRange[row%49])
        case ID.min.rawValue: label.text =  String(minutesRange[row%60])
        case ID.sec.rawValue: label.text = String(secondsRange[row%60])
            
        default:break
        }
        
        return label
    }
}

extension Float {
    func toSlots(_ operation:SlotsManager.SlotsOperation) -> [Int] {
        switch operation {
        case .create:
            return []
        case .edit(let referenceClock):
            guard let referenceClock = referenceClock else { fatalError() }
            let time = Int(referenceClock).time()
            return [time.hr/10, time.hr%10, time.min/10, time.min%10, time.sec/10, time.sec%10]
        }
    }
}

extension EditDurationVC {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        //create larger frame than cellFrame that does not respond to touches, to prevent accidental dismiss when user spins wheels
        guard
            let touchPoint = touches.first?.location(in: nil),
            let lastViewInTheHierarchy = view.hitTest(touchPoint, with: nil),
            ["editDurationView", "container"].contains(lastViewInTheHierarchy.restorationIdentifier)
        else { return }
        
        //make safeFrame larger than cellFrame
        let offsetY = CGFloat(20)
        let originY = cellFrame.origin.y - offsetY
        let height = cellFrame.height + 2 * offsetY
        let size = CGSize(width: cellFrame.width, height: height)
        let safeFrame = CGRect(origin: CGPoint(x: 0, y: originY), size: size)
        
        if !safeFrame.contains(touchPoint) { dismissSelf() }
    }
}

// MARK: - UITableViewDelegate
extension EditDurationVC:UITableViewDelegate {
    func tableView(_ tableView: TV, didSelectRowAt indexPath: IndexPath) {
        
        let cttvc =
        (presentingViewController as? NavigationController)?.viewControllers.first as? CTTVC
        
        let timerDuration = fetchedResultsController.object(at: indexPath)
        
        //replace old with new duration
        cttvc?.replaceInTimer(timerDuration.duration, timer.id?.uuidString)
        
        dismissSelf()
    }
    
    //deleting rows. Both methods bellow must be implemented
    func tableView(_ tableView: TV, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        //⚠️ disables swipe to delete. allows only tap on the minus circle to delete
        if tableView.isEditing { return .delete }
        return .none
    }
}

class TableBackground:UIView {
    var path:UIBezierPath!
    var color:UIColor = .clear {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        path = UIBezierPath(roundedRect: rect, cornerRadius: 30)
        color.setFill()
        UIColor.white.setStroke()
        path.fill()
    }
}

class Label: UILabel { /* decided not to implement anything in the end */}

extension EditDurationVC:NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let timerDurations = fetchedResultsController.fetchedObjects else { return }
        
        //show/hide arrows
        let condition = (1...2).contains(timerDurations.count)
        arrowImages.isHidden = condition ? false : true
        if !arrowImages.isHidden {
            arrowImages.arrangedSubviews.forEach { $0.tintColor = hoursLabelColor }
        }
        
        if timerDurations.isEmpty { background.transform = .identity }
        
        //empty message list
        emptyListMessage.isHidden = timerDurations.isEmpty ? false : true
        emptyListMessage.backgroundColor = timerDurations.isEmpty ? okButtonColor : nil
        maxDurationsImageView.isHidden = timerDurations.isEmpty ? false : true
        
        //3 dots shit
        threeDotsBottom.alpha = shouldShow3Dots ? 1 : 0
        threeDotsTop.alpha = shouldShow3Dots ? 1 : 0
        if threeDotsBottom.alpha == 1 { threeDotsTop.alpha = 0 }
        
        makeAndApplySnapshot(timerDurations)
    }
    
    fileprivate func makeAndApplySnapshot(_ items: [TimerDuration]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TimerDuration>()
        
        if snapshot.numberOfSections == 0 { snapshot.appendSections([.main]) }
        snapshot.appendItems(items, toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension EditDurationVC : UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isTopVisible = isTopVisible(scrollView)
        if shouldShow3Dots {
            if isTopVisible {
                threeDotsTop.alpha = 0
                threeDotsBottom.alpha = 1
            } else {
                threeDotsTop.alpha = 1
                threeDotsBottom.alpha = 0
            }
        }
    }
    
    private func isTopVisible(_ scrollView: UIScrollView) -> Bool {
        guard table.isPagingEnabled else { fatalError() }
        return scrollView.bounds.origin.y == 0 ? true : false
    }
}

class DDS: UITableViewDiffableDataSource<EditDurationVC.Section, TimerDuration> {
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let frc = (tableView.delegate as? EditDurationVC)?.fetchedResultsController
            if let object = frc?.object(at: indexPath) {
                AppDelegate.context.delete(object)
                CoreDataStack.shared.saveContext()
            }
        }
    }
}
