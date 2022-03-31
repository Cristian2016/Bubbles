import UIKit
import CoreData

extension DurationPickerVC:UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.restorationIdentifier! {
        case DurationPickerVC.hrRestorationID:
            return hoursRange.count /* from 0...48 */
        case DurationPickerVC.minRestorationID:
            return minutesRange.count /* from 0...59 */
        case DurationPickerVC.secRestorationID:
            return secondsRange.count /* from 0...59 */
        default:
            return 0
        }
    }
}

extension DurationPickerVC:UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //do not make any UI update here! only Model update ⚠️
        
        //replace in the slotsArray an old pair with a new pair
        //ex: replace [1,2] with [6, 6] in [1,2, 3,4,5,8] -> [6,6, 3,4,5,8]
        let newPair:ArraySlice<Int>
        var oldPair:ArraySlice<Int>
        
        //digitsSlots array is changed each time the user makes a new selection
        switch pickerView.restorationIdentifier! {
        case DurationPickerVC.hrRestorationID:
            slotsManager.state = .spins(.hours)
            
            newPair = digitsPair(from: hoursRange[row])
            oldPair = slots[0...1]
            if oldPair != newPair {
                slotsManager.replace(.hours, with: hoursRange[row])
            }
            
        case DurationPickerVC.minRestorationID:
            slotsManager.state = .spins(.minutes)
            
            newPair = digitsPair(from: minutesRange[row])
            oldPair = slots[2...3]
            if oldPair != newPair {
                slotsManager.replace(.minutes, with: minutesRange[row])
            }
            
        case DurationPickerVC.secRestorationID:
            slotsManager.state = .spins(.seconds)
            
            newPair = digitsPair(from: secondsRange[row])
            oldPair = slots[4...5]
            if oldPair != newPair {
                slotsManager.replace(.seconds, with: secondsRange[row])
            }
            
        default: break
        }
        
        //exception maxDuration 48Hr
        if slots.count > 1 && slots[0...1] == [4,8] { slotsManager.slots = [4,8,0,0,0,0] }
        
        //exception 00_00_00
        if slotsManager.isCombinationForbidden { slotsManager.slots = [0,0,0,0,0,1] }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        
        let fontSize:CGFloat = isIPodTouch7 ? 60 : durationFontSize
        //⚠️ must use monospaced otherwise blinds will not cover slots completely
        //make font smaller for iPod Touch 7 [screen width 320]
        label.font = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
        
        label.textColor = .label
        let text:String
        
        switch pickerView.restorationIdentifier! {
        case DurationPickerVC.hrRestorationID:
            text = formattedText(from: hoursRange[row])
        case DurationPickerVC.minRestorationID:
            text = formattedText(from: minutesRange[row])
        case DurationPickerVC.secRestorationID:
            text = formattedText(from: secondsRange[row])
        default:
            text = String()
        }
        
        label.text = text
        label.textAlignment = .center
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { pickerViewRowHeight }
    
    // MARK: - Little Helpers
    private func digitsPair(from number:Int) -> ArraySlice<Int> {
        [number/10, number%10]
    }
}

extension DurationPickerVC {
    typealias NF = NumberFormatter
}

class DurationPickerVC:UIViewController, SlotsManagerDelegate {
    
    internal let durationFontSize = CGFloat(70)
    private var okButtonShownAlready = false
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel! {didSet{
        switch payload?.timerOperation {
        case .create(digitColor: _, digitColorAsString: _):
            titleLabel.text = digitColorAsString
        default:
            titleLabel.text = bubbleTitle
        }
        
        let textColor = titleLabel.isDarkModeOn && digitColor == UIColor.charcoal ? .white : digitColor
        titleLabel.textColor = textColor
    }}
    
    @IBOutlet weak var titleStack: UIStackView! {didSet{
        let screenHeight = UIScreen.main.bounds.height
        //hide title on short devices, ex: iPhone 8 or iPod Touch
        //736 screenHeight iPhone 8 Plus, 667 iPhone 8 https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
        if screenHeight <= 736 {
            titleLabel.textColor = .clear
        }
    }}
    
    //cover views: cover hours minutes seconds
    @IBOutlet var blinds: [UIView]!
    
    @IBOutlet var pickers: [UIPickerView]! {didSet{
        //authorization requested only once
        ScheduledNotificationsManager.shared.requestAuthorization()
        changeWheelSelectionViewLook()
    }}
    
    private func changeWheelSelectionViewLook() {
        //hide selection view background and make black contour instead
        delayExecution(.now() + 0.05) {[weak self] in
            guard let self = self else { return }
            
            let color = self.view.isDarkModeOn ? UIColor.white : .black
            self.pickers.forEach { $0.changeSelectionViewLook(borderColor:color) }
        }
    }
    
    // MARK: - Properties
    static let hrRestorationID = "hours"
    static let minRestorationID = "minutes"
    static let secRestorationID = "seconds"
    
    //which pickers to enable or disable are stored in dictionaries
    private let enableDic = [2:DurationPickerVC.hrRestorationID,
                             4:DurationPickerVC.minRestorationID,
                             6:DurationPickerVC.secRestorationID]
    
    private let disableDic = [1:DurationPickerVC.hrRestorationID,
                              3:DurationPickerVC.minRestorationID,
                              5:DurationPickerVC.secRestorationID]
    
    //used to make wheel font size smaller when on iPodTouch7
    lazy var screenWidth = UIScreen.main.bounds.width
    lazy var isIPodTouch7 = screenWidth == 320
    
    ///enable disable pickers
    private func togglePickers() {
        switch slotsManager.state {
        case .grows:
            pickers.filter ({
                $0.restorationIdentifier == enableDic[slots.count]
            }).first?.isUserInteractionEnabled = true
            
        case .shrinks:
            guard !slots.isEmpty else { break }
            
            let row = slotsManager.slots[slotsManager.slots.count - 1]
            
            let picker = pickers.filter ({ $0.restorationIdentifier == disableDic[slots.count]
            }).first
            
            picker?.selectRow(row * 10, inComponent: 0, animated: false)
            picker?.isUserInteractionEnabled = false
            
        case .zeroDigits:
            pickers.forEach { $0.isUserInteractionEnabled = false }
            
        case .sixDigits:
            pickers.forEach { $0.isUserInteractionEnabled = true }
            
        case .spins(_) : break
        }
    }
    
    //open or close blinds and programmatically rotate pickers, enable or disable a picker to rotate
    private func updateBlinds() {
        //all blinds closed id no digits displayed
        if slots.isEmpty {
            blinds.forEach { $0.alpha = 1 }
            pickers.forEach { $0.selectRow(0, inComponent: 0, animated: false) }
        }
        
        if slotsManager.slots == [4,8,0,0,0,0] {
            blinds.forEach { $0.alpha = 0 }
            pickers.forEach { $0.isUserInteractionEnabled = true }
            let hours = pickers.filter { $0.restorationIdentifier == DurationPickerVC.hrRestorationID }.first
            hours?.selectRow(DurationPickerVC.maxDuration, inComponent: 0, animated: true)
            
            return
        }
        
        switch slotsManager.state {
        case .grows:
            let upperIndex = slots.count - 1
            blinds[upperIndex].alpha = 0
            if upperIndex > 0, blinds[upperIndex - 1].alpha == 1 {
                blinds[upperIndex - 1].alpha = 0
            }
            
        case .shrinks:
            let upperIndex = slots.count
            blinds[upperIndex].alpha = 1
            
        case .sixDigits:
            switch payload?.timerOperation {
            case .editDuration(_, _, let timerReferenceClock, _):
                blinds.forEach { $0.alpha = 0 }
                pickers.forEach { $0.isUserInteractionEnabled = true }
                
                let durationComponents = Int(timerReferenceClock).time()
                pickers.forEach {
                    switch $0.restorationIdentifier! {
                    case DurationPickerVC.hrRestorationID:
                        $0.selectRow(durationComponents.hr, inComponent: 0, animated: false)
                        
                    case DurationPickerVC.minRestorationID:
                        $0.selectRow(durationComponents.min, inComponent: 0, animated: false)
                        
                    case DurationPickerVC.secRestorationID:
                        $0.selectRow(durationComponents.sec, inComponent: 0, animated: false)
                        
                    default: break
                    }
                }
            default: break
            }
            
        case .zeroDigits:
            break
            
        default: break
        }
        togglePickers()
    }
    
    // MARK: - Properties
    //Incoming Data either from PaletteVC or MoreOptionsVC
    var payload:Payload? {didSet{
        if let payload = payload {
            switch payload.timerOperation {
            case .editDuration(let color, let id, let referenceClock, let bubbleTitle):
                digitColor = color ?? .clear
                timerID = id
                timerReferenceClock = referenceClock
                self.bubbleTitle = bubbleTitle
                
            case .create(digitColor: let color, digitColorAsString: let colorAsString):
                digitColor = color
                digitColorAsString = colorAsString
            }
        }
    }}
    
    //properties extracted from payload
    var digitColor = UIColor.clear
    var digitColorAsString = String()
    var timerID:String?
    var timerReferenceClock:Float?
    var bubbleTitle:String?
    
    let hoursRange = CountableRange(0...maxDuration)
    let minutesRange = CountableRange(0...59)
    let secondsRange = CountableRange(0...59)
    
    let pickerViewRowHeight = CGFloat(100)
    
    //programmatically spin current picker
    private func updateSlotsInCurrentPicker() {
        switch slotsManager.state {
        case .grows:
            preventDurationAbove48Hours()
            
            let bothCurrentPickerSlotsToFill = slots.count%2 == 0
            //you fill either both slots or one slot
            let row = bothCurrentPickerSlotsToFill ? slots[slots.count - 2]*10 + slots.last! : slots.last!*10
            currentPicker.selectRow(row, inComponent: 0, animated: true)
            
        case .spins:
            break
        case .shrinks:
            break
        default:
            break
        }
    }
    
    //UI part only!
    ///six slots in total. one /pair of slots/ for each /duration component/. seconds slots + minutes slots + hours slots = 6 slots
    internal var slots = [Int]() {didSet{
        switch slotsManager.state {
        case .grows:
            updateSlotsInCurrentPicker()
            
        case .spins(_):
            preventDurationAbove48Hours()
            preventAllDigitsZero()
        
        case .shrinks:
            preventDurationAbove48Hours()
            
        default: break
        }
        
        updateBlinds()
        updateUI(speechBubbleAnimation: false)
        userFriendlyDuration.text = userFriendlyDuration(from:slotsAsString)
    }}
    
    internal var slotsAsString:String { slots.reduce(String.empty) { $0 + String($1) } }
    
    private func isUserAllowedToSpinWheel() -> Bool {
        return false
    }
    
    private enum Slot {
        case hours
        case minutes
        case seconds
    }
    private func isComplete(_ slot:Slot) -> Bool {
        switch slot {
        case .hours:
            if slots.count >= 2 { return true }
        case .minutes:
            if slots.count >= 4 { return true }
        case .seconds:
            if slots.count == 6 { return true }
        }
        
        return false
    }
    
    //each time digitSlots changes, UI must react to these changes
    private func matchUIToDigitSlots() {
        if slots.isEmpty {
            //if no slot complete, pickers are set to zero
            resetPickers(animated: true)
            //match digits
        } else {
            switch slots.count {
            case 1:
                //4 -> second digit must be from 0...8
                //uncover h1
                break
            case 2:
                break
                //48 -> disable minutes and seconds pickers, show Ok button
                //hourSlot complete
            case 3:
                //uncover m1
                break
            case 4:
                //hourSlot and minuteSlot complete
                break
            case 5:
                break
            case 6:
                //hourSlot, minuteSlot and secondSlot complete
                //show OK button
                break
            default: break
            }
        }
    }
    
    private func resetPickers(animated:Bool) {
        pickers.forEach {
            if $0.selectedRow(inComponent: 0) != 0 {
                $0.selectRow(0, inComponent: 0, animated: animated)
            }
        }
    }
    
    private var currentPicker:UIPickerView {
        pickers.filter {
            switch slots.count {
            case 1...2:
                return $0.restorationIdentifier == DurationPickerVC.hrRestorationID
            case 3...4:
                return $0.restorationIdentifier == DurationPickerVC.minRestorationID
            case 5...6:
                return $0.restorationIdentifier == DurationPickerVC.secRestorationID
            default:
                return $0.restorationIdentifier == DurationPickerVC.hrRestorationID
            }
        }.first!
    }
    
    //charcoal and chocolate
    private let darkColors = [UIColor.charcoal, .chocolate]
    
    private var darkModeCondition:Bool {
        traitCollection.userInterfaceStyle == .dark
        && darkColors.contains(digitColor)
    }
    
    internal static let maxDuration = 48/* hours */
    
    internal lazy var speechBubble:UIImageView = {
        /* 🤔 can cause retain cycle? */
        let imageView = UIImageView()
        imageView.customize(for: .speechBubble)
        imageView.frame.size = imageView.image?.size ?? .zero
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var okButton:OKButton = {
        let button = OKButton(digitColor)
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let durationInputManager = TimerDurationInputManager()
    
    internal lazy var slotsManager = SlotsManager(timerID == nil ? .create : .edit(timerReferenceClock))
    
    // MARK: - Methods
    ///ex: 13 -> "13", 7 -> "07"
    private func formattedText(from number:Int) -> String {
        NF.zeroPadding.intAsString(number)!
    }
    
    ///maxDuration 48Hr. make sure all wheels match "48_00_00"
    private func preventDurationAbove48Hours() {
        guard slots.count > 1, slots[0...1] == [4,8] else { return }
        
        pickers.forEach {
            let isMinutes = $0.restorationIdentifier == DurationPickerVC.minRestorationID
            let isSeconds = $0.restorationIdentifier == DurationPickerVC.secRestorationID
            
            if  isMinutes || isSeconds {
                if $0.selectedRow(inComponent: 0) != 0 {
                    $0.selectRow(0, inComponent: 0, animated: true)
                }
            }
        }
    }
    
    ///00_00_00 combination is not allowed
    private func preventAllDigitsZero() {
        if slotsManager.isCombinationForbidden {
            let seconds = pickers.filter { $0.restorationIdentifier == DurationPickerVC.secRestorationID }.first
            seconds?.selectRow(1, inComponent: 0, animated: true)
        }
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set data source and delegate for pickers
        pickers.forEach {
            $0.dataSource = self
            $0.delegate = self
        }
        
        slotsManager.delegate = self
    }
    
    // MARK: - Outlets
    @IBOutlet weak var deleteButton: Digit!
    
    //all digits [0...9] and delete button [x]
    @IBOutlet var digits:[Digit]! {didSet{
        digits.forEach {
            //set background colors for digits and clear button
            let isClearButton = $0.currentTitle == "✕"
            $0.fillColor = isClearButton ? UIColor.red : digitColor
            
            //white text color if charcoal or chocolate and darkmode. both for digits and clear button
            if darkModeCondition { $0.setTitleColor(.white, for: .normal) }
        }
    }}
    
    //okButton is added to this container when the user enters a correct duration
    @IBOutlet weak var okButtonContainer: UIStackView!
    
    @IBOutlet weak var durationStack: UIStackView!
    
    @IBOutlet weak var speechBubbleContainer: UIView!
    
    //appears only when OK button appears
    @IBOutlet weak var userFriendlyDuration: UILabel! {didSet{
        //hidden by default
        userFriendlyDuration.alpha = 0
    }}
    
    @IBOutlet var underLabels: [UILabel]!
    
    private func showUnderLabels(_ show:Bool) {
        underLabels.forEach { $0.textColor = show ? .systemGray : .systemBackground }
        userFriendlyDuration.alpha = show ? 0 : 1
    }
    
    // MARK: - User Intents
    ///updates displayedDuration and new displayedDuration triggers UI update
    @IBAction func digitTouched(_ digit:Digit) {
        guard slots.count < 6 else { fatalError("slots.count 6 already") }
        
        //update Model
        slotsManager.appendToSlots(digit.currentTitle)
        
        //haptic Feedback
        UserFeedback.triggerSingleHaptic(.light)
    }
    
    @IBAction func deleteTouched(_ button:Digit) {
        guard slots.count > 0 else { fatalError("slots empty already") }
        
        slotsManager.emptyLastSlot()
        updateBlinds()
        
        //haptic and visual feedback
        UserFeedback.triggerSingleHaptic(.light)
        updateUI(speechBubbleAnimation: false)
    }
    
    @IBAction func deleteTapAndHold(_ gesture:LongPress) {
        
        if case LongPress.State.began = gesture.state {
            
            UserFeedback.triggerDoubleHaptic(.light)
            
            //Model update
            slotsManager.emptyAllSlots()
            //UI update not here! I do UI update in slots
        }
    }
    
    @objc private func okButtonTapped() {
        /* 1.create new timer */
        /* 2.dismiss to view controller */
        
        switch slotsManager.operation {
        case .edit /* timer */(referenceClock: _):
            let newReferenceClock /* from slots */ = slotsManager.slotsToReferenceClock
            let cttvc = (navigationController?.viewControllers.first as? CTTVC)
            cttvc?.replaceInTimer(newReferenceClock, timerID)
            
        case .create: /* new timer */
            createTimer(duration: finalTimerDuration(), color: digitColorAsString)
        }
        
        UserFeedback.triggerSingleHaptic(.medium)
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    // MARK: - Methods
    private func createTimer(duration:Int, color:String) {
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: EntityName.ct, in: AppDelegate.context) {
            let timer = CT(entity: entityDescription, insertInto: AppDelegate.context)
            timer.populate(color: color, kind: .timer(limit: duration))
        }
        
        /* if I dont put delay i get warning */
        delayExecution(.now() + 0.1) { CoreDataStack.shared.saveContext() }
    }
    
    //digit can either be 0...9 or delete button
    private func updateSlots(_ digit:Digit) {
        //special case digit "00"
        
        let condition = slots.count%2 == 0
        
        switch slotsManager.state {
        case .grows:
            let row = condition ? slots[slots.count - 2]*10 + slots.last! : slots.last!*10
            currentPicker.selectRow(row, inComponent: 0, animated: true)
        default:break
        }
    }
    
    private func userFriendlyDuration(from:String) -> String {
        var displayedString = String.empty
        
        let dic = [0:" hr ", 1:" min ", 2:" sec "]
        let substrings = from.split(into: 2)
        
        substrings.enumerated().forEach { (index, substring) in
            if let suffix = dic[index] {
                if substring.count == 2 {
                    if substring.first! == "0" {
                        var substringCopy = substring
                        substringCopy.removeFirst()
                        if substringCopy != "0" {
                            displayedString.append(String(substringCopy).appending(suffix))
                        }
                    } else {
                        displayedString.append(String(substring).appending(suffix))
                    }
                }
            }
        }
        
        if from == String(DurationPickerVC.maxDuration) { return displayedString }
        if from.count < 6 { displayedString.append("...") }
        
        return displayedString
    }
    
    ///duration entered by user converted into seconds
    private func finalTimerDuration() -> Int {
        let splits = slotsAsString.split(into: 2)
        
        guard splits.count == 3 else {
            return (slotsAsString == String(DurationPickerVC.maxDuration)) ? DurationPickerVC.maxDuration*3600/* sec */ : -1
        }
        
        let secondsDict = [0:3600, 1:60, 2:1]
        
        //grab duration
        var totalDuration = 0
        for (index, split) in splits.enumerated() {
            totalDuration += secondsDict[index]! * Int(String(split))!
        }
        return totalDuration
    }
    
    // MARK: -  overrides
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.layoutIfNeeded()
        updateUI(speechBubbleAnimation: true)
    }
    
    /// ViewController method
    private func changeDigitState(to state: Digit.State, for characters:Characters) {
        digits.forEach { $0.buttonState = .enabled } // enable first all buttons
        
        let forbiddenCharacters = durationInputManager.charactersToDisable(for: slotsAsString)
        
        digits.forEach {
            
            if let digitSymbol = $0.currentTitle {
                if let forbiddenCharacter = Unicode.Scalar(digitSymbol) {
                    $0.buttonState = forbiddenCharacters.contains(forbiddenCharacter) ? state : .enabled
                } else {
                    // FIXME: - fix double 00 here?
                    $0.buttonState = forbiddenCharacters.contains(Unicode.Scalar("*")) ? state :.enabled
                }
            }
        }
    }
    
    // MARK: - organize
    internal var shouldIChangeDefaultSuperviewForInfoPicture = false
}

extension DurationPickerVC {
    private enum DisplayedDurationState {
        case start /* DP presented first time to the user */
        case editing /* user edits DP.display.text */
        case completed /* user entered a valid timer duration */
    }
    
    private var displayedDurationState: DisplayedDurationState {
        switch slotsAsString.count {
        case 0: return .start /*empty string*/
        case 2 where slotsAsString == String(DurationPickerVC.maxDuration), 6: return .completed
        default: return .editing
        }
    }
    
    ///user edits display.text, touches digits, deletes digits, clears display.text, changes in display.text trigger UI updates
    private func updateUI(speechBubbleAnimation:Bool) {
        updateDigits()
        updateSpeechBubble(withAnimation:speechBubbleAnimation)
    }
    
    private func updateDigits() {
        let characters = durationInputManager.charactersToDisable(for: slotsAsString)
        changeDigitState(to: .disabled, for: characters)
        
        if case DurationPickerVC.DisplayedDurationState.completed = displayedDurationState {
            let characters = durationInputManager.charactersToDisable(for: slotsAsString)
            changeDigitState(to:.hidden, for:characters)
            
            if okButtonShownAlready == false {
                okButton.toggle(.add, okButtonContainer)
                animateOkButton()
                okButtonShownAlready = true
            }
            
            if darkModeCondition {
                digits.forEach { $0.setTitleColor(.black, for: .normal) }
            }
            showUnderLabels(false)
            userFriendlyDuration.alpha = 1.0
            
        } else {
            okButton.toggle(.remove, okButtonContainer)
            okButtonShownAlready = false
            
            showUnderLabels(true)
            userFriendlyDuration.alpha = 0.0
            if darkModeCondition {
                digits.forEach { $0.setTitleColor(.white, for: .normal) }
            }
        }
    }
    
    func animateOkButton() { okButton.pulsateAnimate() }
}
extension DurationPickerVC:InfoPictureProtocol {
    
    internal var superview: UIView {
        if !shouldIChangeDefaultSuperviewForInfoPicture { return view }
        else { return view }
    }
    
    func toggleInfoPicture(situation: InfoPictureSituation) {
        switch situation {
        case .durationPicker:
            guard situation == .durationPicker else { return }
            shouldIChangeDefaultSuperviewForInfoPicture = false
            
            if infoPicFoundInSuperview(for: situation) {
                searchInSuperviewInfoPic(for: situation)?.removeFromSuperview()
            }
            else { superview.addSubviewInTheCenter(makeInfoPic(for: situation)) }
            
        default: break
        }
    }
}

extension DurationPickerVC {
    func updateSpeechBubble() {
        speechBubble.customize(for: .speechBubble)
    }
}

extension DurationPickerVC {
    ///data coming from either PaletteVC or MoreOptionsVC when DurationPickerVC is about to be presented
    struct Payload {
        enum TimerOperation {
            case create (digitColor:UIColor, digitColorAsString:String)
            case editDuration (_ color:UIColor?, _ id:String?, _ referenceClock:Float, _ title:String)
        }
        
        let timerOperation:TimerOperation
    }
}

extension DurationPickerVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        matchTitleAndDigitsColorToDarkMode(previousTraitCollection)
    }
    
    // MARK: - Helper
    //charcoal color is the problem. if the darkmode is on text color should be white, else color stays charcoal
    private func matchTitleAndDigitsColorToDarkMode(_ previousTraitCollection: UITraitCollection?) {
        
        //change charcoal color when darkmode to white or back to charcoal if lightmode
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            if digitColorAsString == "Charcoal" {
                titleLabel.textColor = titleLabel.isDarkModeOn ? .white : .charcoal
                changeWheelSelectionViewLook()
            }
        }
    }
}
