import UIKit
import CoreData
import CoreHaptics
import WidgetKit
import Intents

//user tap start & pause
//user long press
//system ends session zeroTimer
//user changes sticky note

extension CTTVC {
    typealias NC = NotificationCenter
    typealias DDS = UITableViewDiffableDataSource<Section, CT>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CT>
    typealias FRC = NSFetchedResultsController<CT>
    typealias SwipeConfiguration = UISwipeActionsConfiguration
    
    typealias Controller = NSFetchedResultsController<NSFetchRequestResult>
    typealias SnapshotReference = NSDiffableDataSourceSnapshotReference
    typealias ActionsConfig = UISwipeActionsConfiguration
    typealias TV = UITableView
    typealias IP = IndexPath
    
    typealias DropProposal = UITableViewDropProposal
    typealias TableView = UITableView
    typealias DropCoordinator = UITableViewDropCoordinator
    typealias Drop = UIDropSession
    
    typealias LongPress = UILongPressGestureRecognizer
}

extension CTTVC:HintsManagerDelegate { }

class CTTVC: UITableViewController {
    //manage undosave hint
    lazy var ephemeralArray = EphemeralArray<IndexPath>(lifespan: 5)
    
    // MARK: - UserHintView
    var hintView:UserHintView?
    
    ///indexPaths for undoSave action are stored here
    internal var undoSave_IndexPathDate_Tuples = [(indexPath:IndexPath, date:Date)]()
    
    internal func clearUndoSaveHint_IndexPaths() {
        undoSave_IndexPathDate_Tuples.forEach {
            getCell(for: $0.indexPath.row)?.showUndoSaveHint(false) }
        undoSave_IndexPathDate_Tuples = []
    }
    
    lazy var hintViewManager = HintsManager(self)
    
    internal var undoSaveActionDate:Date?
    internal let undoLastActionDuration = TimeInterval(5.0)
    
    override func viewDidLayoutSubviews() {
        hintViewManager.removeHintViewIfNeeded()
    }
    
    // MARK: - Scroll and select
    var indexPathOfRowToBeSelected:IndexPath?
    
    // MARK: -
    let hourLabelAlphaForInvisible = CGFloat(0.011)
    
    // MARK: -
    var singleTapDate:Date?
    
    ///Fetched Results Controller
    private(set) var frc:FRC!
    // MARK: - Widgets

    // MARK: - Diffable DataSource
    enum Section:CustomStringConvertible {
        case main
        var description: String { "Section" }
    }
    var dds:DataSource!
    
    var userHasJustDraggedAndDroppedInTableView:Bool?
    var dragAndDropInfo:DragAndDropInfo?
        
    ///setup a diffableDataSource for CoreData
    private func setDataSource() {
        tableView.dataSource = dds
        
        dds = DataSource(tableView: tableView) {
            [weak self] (tv, indexPath, bubble) in
            
            guard
                let self = self,
                let cell = tv.dequeueReusableCell(withIdentifier: Cell.ctCell, for: indexPath) as? CTCell
            else { return CTCell() }
                                    
            if cell.delegate == nil { cell.delegate = self }
            cell.tricolor = TricolorProvider.tricolors.filter {$0.name == bubble.color}.first
            cell.hide(true, cell.doneSticker) /* clear first */
            
            //done sticker
            if bubble.isTimer {
                switch bubble.state {
                case .running, .brandNew, .paused: cell.hide(true, cell.doneSticker)
                case .zeroTimer: cell.hide(false, cell.doneSticker)
                }
            }
            
            //widget
            if bubble.hasSquareWidget {
                cell.shapeShift(.square())
            } else {
                if case ShapeShifterKind.square(radius:_) = cell.secondsButton.kind {
                    cell.shapeShift(.circle)
                }
            }
            
            //start sticker
            cell.hide((bubble.state == .running) ? true : false, cell.startSticker)
            if bubble.isTimer && bubble.currentClock <= 0 {
                cell.hide(true, cell.startSticker)
            }
            
            //sticky note
            cell.stickyNote.field.text = String.empty /* clear first */
            
            cell.stickyNote.alpha = bubble.stickyNoteVisible ? 1 : 0
            cell.stickyNote.field.text = bubble.stickyNote
            
            //calendar enabled timeBubbles
            cell.stickyNote.slidingBackground.color = bubble.isCalendarEnabled ?
                                                    cell.calendarColor : cell.nonCalendarColor
            cell.setupCalendarSticker(for: bubble, animated: false)
            
            //duration visible
            cell.durationHoursLabel.alpha = 0 /* clear first */
            cell.durationMinutesLabel.alpha = 0
            cell.durationSecondsLabel.alpha = 0
            
            if bubble.isTimer {
                cell.durationHoursLabel.alpha = bubble.durationVisible ? 1 : 0
                cell.durationMinutesLabel.alpha = bubble.durationVisible ? 1 : 0
                cell.durationSecondsLabel.alpha = bubble.durationVisible ? 1 : 0
                
                //time components
                let timeComponents = Int(bubble.referenceClock).time()
                cell.durationHoursLabel.text = String(timeComponents.hr)
                cell.durationMinutesLabel.text = String(timeComponents.min)
                cell.durationSecondsLabel.text = String(timeComponents.sec)
        
                //color
                let color = self.durationDisplayColor(for: bubble)
                cell.durationHoursLabel.textColor = color
                cell.durationMinutesLabel.textColor = color
                cell.durationSecondsLabel.textColor = color
            }
            
            //marble
            cell.marble.alpha = bubble.isTimer ? 1 : 0
            
            self.updateTimeComponents(bubble, cell)
            
            cell.secondsButton.tag = indexPath.row
            
            cell.secondsButton.addTarget(self, action: #selector(self.secondsButtonTapped(button:)), for: .touchUpInside)
            
            (cell.secondsButton.gestureRecognizers?.first as? LongPress)?.addTarget(self, action: #selector(self.secondsButtonPressed(gesture:)))
            
            if bubble.isTimer {
                //handle edit duration in CTTVC
                cell.doubleTap.addTarget(self, action: #selector(self.handleDoubleTap(_:)))
            } else {
                cell.doubleTap.removeTarget(self, action: #selector(self.handleDoubleTap(_:)))
            }
            
            return cell
        }
    }
    
    ///setup a fetchedResultsController
    private func setFetchedResultsController() {
        let request:NSFetchRequest<CT> = CT.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(CT.rank), ascending: false)]
        
        frc = NSFetchedResultsController(fetchRequest: request,
                                                        managedObjectContext: context,
                                                        sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = self
    }
    
    fileprivate func updateTimeComponents(_ ct: CT, _ cell: CTCell) {
        /*
         1.clear content from previous cells
         2.put time content Hr Min and Sec
         3.show all labels for timers
         4.fine tune alpha values:
         5.show all labels for timers
         show/hide labels for stopwatches depending on how much
         time they have already displayed
         */
        
        cell.hoursLabel.text = String.empty
        cell.minutesLabel.text = String.empty
        cell.secondsButton.setTitle(String.empty, for: .normal)
        
        //display fakeClock if bubble is running
        //display currentClock if bubble is NOT running
        let userNeedle = (ct.state != .running) ? ct.userNeedle : ct.fakeClock ?? 0
        
        cell.hoursLabel.text = String(userNeedle.time().hr)
        cell.minutesLabel.text = String(userNeedle.time().min)
        cell.secondsButton.setTitle(String(userNeedle.time().sec), for: .normal)
        
        if ct.isTimer {
            cell.minutesLabel.alpha = 1
            cell.invisibleHoursLabel(false)
        }
        
        if !ct.isTimer {
            let stopwatchIsUnderOneMinute = userNeedle.time().min == 0 &&
                                            userNeedle.time().hr == 0
            
            cell.minutesLabel.alpha = stopwatchIsUnderOneMinute ? 0 : 1
            cell.invisibleHoursLabel((userNeedle.time().hr < 1) ? true : false)
        }
        
        //display hms in reverse order if hours exceeds more than 2 digits
        //https://share.icloud.com/photos/0xfgc4qzqSyOeX6TL53fZPFMw
        if !ct.isTimer {
            self.ifNeededDisplayTimeComponentsInReverseOrder(for: cell)
        }
    }
    
    let notificationsManager = ScheduledNotificationsManager.shared
    
    var isTableViewEmpty:Bool? {didSet{
        if isTableViewEmpty != nil {
            showEmptyListInfo(show: isTableViewEmpty! ? true : false)
        }
    }}
    
    ///toggles a scrollView with an image, nothing less nothing more :)
    private func showEmptyListInfo(show:Bool) {
        if show {
            //make sure there is no welcomeView already
            view.subviews.forEach {
                if $0.restorationIdentifier == "welcomeView" {
                    $0.removeFromSuperview()
                }
            }
            
            let welcomeView = WelcomeView(frame: view.bounds)
            view.addSubview(welcomeView)
            tableView.isScrollEnabled = false
        } else {
            view.subviews.forEach { if $0.restorationIdentifier == "welcomeView" { $0.removeFromSuperview()} }
            tableView.isScrollEnabled = true
        }
    }
    
    // MARK: - copied
    typealias Animation = CAKeyframeAnimation
    var cellsPerPage:Int = CellsPerPageCalculator().cellsCount
    
    private lazy var rowHeight:CGFloat = {
        /*can't compute rowHeight if window is nil*/
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0
        let screenHeight = view.window?.frame.height ?? 0.0
        return ((screenHeight - statusBarHeight) / CGFloat(cellsPerPage)).rounded()
    }()
    
    func bubble(at indexPath:IndexPath) -> CT {
        frc.object(at: indexPath)
    }
    
    // MARK: - organize
    private func checkAndEndAnyZeroTimers(_ userNeedle:Int, _ bubble:CT) {
        guard bubble.isTimer, userNeedle <= 0,
              bubble.state != .brandNew
        else {return}
        
        //UI part. make sure all time components are zero "0:0:0"
        if
            let indexPath = frc.indexPath(forObject: bubble),
            let cell = getCell(for: indexPath.row) {
            
            let condition0 = cell.secondsButton.currentTitle == "0"
            let condition1 = cell.minutesLabel.text == "0"
            let condition2 = cell.hoursLabel.text == "0"
            
            let allComponentsAreZero = condition0 && condition1 && condition2
            
            if !allComponentsAreZero {
                cell.secondsButton.setTitle("0", for: .normal)
                cell.minutesLabel.text = "0"
                cell.hoursLabel.text = "0"
            }
        }
        
        //Model
        bubble.declareZeroTimer()
    }
    
    //prevent keyboard to cover the cell
    //used only when keyboard is onscreen
    private var cellBoundsInTableViewCoordinateSpace:CGRect?
        
    // MARK:
    internal var id_ofTimer_EagerToRepeat:String? {didSet{
        //user can restart a timer either using the startPauseButton or when user presses notification
        self.restartTimers_UserPressedNotification()
    }}
    
    internal var indexPathOfRowToSelect:IP? //Local Notifications extension
    
    private func restartTimers_UserPressedNotification() {
        guard
            let id = id_ofTimer_EagerToRepeat,
            let cts = frc.fetchedObjects
        else { return }
        
        //filter all the timers to make your work easier??
        let timers = cts.filter { $0.isTimer }
        
        let timerToRepeat = timers.filter { $0.id!.uuidString == id }.first
        if let timerToRepeat = timerToRepeat {
            id_ofTimer_EagerToRepeat = nil
            
            endSession(timerToRepeat)
            start(true, timerToRepeat)
        }
    }
    
    private var tableViewWentUpToShowTextField = false /* 1▶︎ */
    
    ///cell.indexPath cooresponding to the timer that entered editMode in EditDurationVC
    internal var editDurationIndexPath:IndexPath?
        
    // MARK: -
    private let context = AppDelegate.context /* ⚠️ you should put it somwhere else maybe */
    private let coreDataStack = CoreDataStack.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        INPreferences.requestSiriAuthorization { status in
//            print(status.rawValue)
//        }
                
        //user enters a sticky note and keyboard dismissed when user taps outside the field
        view.setupKillKeyboard()
        
        //drag and drop support
        tableView.dragInteractionEnabled = true /* local drags on phones */
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        fixTableViewTopContentInset()
        
        // MARK: -
        view.insetsLayoutMarginsFromSafeArea = false
        tableView.clipsToBounds = false
        tableView.separatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        
        /* register cell */
        let cellNib = UINib(nibName: "ChronoTimerCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: Cell.ctCell)
        
        registerFor_KeyboardFrame_Updates()
        registerFor_TexfieldDidBeginEditing()
        
        /* add self as observer to observe changes in the ChronoTimer.needle property */
        register_For_NeedleUpdate()
        registerFor_repeatTimerWhenYouWakeUp()
        
        registerFor_DidEnterBackground()
        
        registerFor_DidBecomeActive()
        registerFor_WillResignActive()
        
        // MARK: - Diffable Data Source
        setFetchedResultsController()
        setDataSource()
        
        //user activity
        createUserActivity(.pauseAll)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        toggleInfoPicture(situation: .firstWelcome)
    }
    
    //View is about to be made visible. It hasn't yet fully transitioned onscreen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //⚠️ do not make frc perform fetch when unneccessary
        if frc.fetchedObjects == nil { try? frc.performFetch() }
        
        // FIXME: review this!
        //marble animation stopped when user switches to another VC, so it must continue to run when user returns to CTTVC
        if Date().timeIntervalSince(AppDelegate.appLaunchDate) > 0.3 {
            frc?.fetchedObjects?.forEach {
                [weak self] bubble in
                delayExecution(.now() + 0.05) {
                    self?.syncMarble(of:bubble, for:.enterOnline)
                }
            }
        }
    }
    
    // MARK: - Init/Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    enum MarbleStage {
        case initial /* zeroTimer/endSession */
        case userStart
        case userPause /* not estimated */
        case enterOnline /* estimated start */
        case enterOffline /* simply pause, do not compute anything */
        case tableViewWillDisplayCell
    }
    
    func syncMarble(of timer:CT, for stage:MarbleStage) {
        guard
            timer.isTimer, timer.state != .zeroTimer,
            let indexPath =  frc.indexPath(forObject: timer),
            let cell = tableView.cellForRow(at: indexPath) as? CTCell
        else { return }
                
        switch stage {
        case .initial:
//            print("syncMarble initial", timer.color!)
            cell.marbleRotation(.identity)
            
        case .enterOffline:
//            print("syncMarble enterOffline", timer.color!)
            cell.marbleRotation(.stop(0))
            
        case .userPause:
//            print("syncMarble userPause", timer.color!)
            delayExecution(.now() + 0.01) {
                let afc = timer.currentAngularFractionComplete(isEstimated: false)
                cell.marbleRotation(.stop(afc.reachedAngle))
            }
            
        case .userStart:
            guard timer.state == .running else { return}
            
//            print("syncMarble userStart", timer.color!)
            
            let afc = timer.currentAngularFractionComplete(isEstimated: false)
            cell.marbleRotation(.start(afc.remainingDuration, afc.reachedAngle))
            
        case .tableViewWillDisplayCell:
//            print("syncMarble tableViewWillDisplayCell", timer.color!)
            switch timer.state {
            case .running:
                let afc = timer.currentAngularFractionComplete(isEstimated: true)
                cell.marbleRotation(.start(afc.remainingDuration, afc.reachedAngle))
                
            case .brandNew, .zeroTimer:
                if cell.marble.transform != .identity {
                    cell.marbleRotation(.identity)
                }
                
            case .paused:
                let afc = timer.currentAngularFractionComplete(isEstimated: false)
                cell.marbleRotation(.stop(afc.reachedAngle))
            }
            
        case .enterOnline /* either viewWillDisplay or SceneDelegate.willEnterForeground */:
            guard timer.state == .running else { return}
            
//            print("syncMarble enterOnline", timer.color!)
            
            let afc = timer.currentAngularFractionComplete(isEstimated: true)
            cell.marbleRotation(.start(afc.remainingDuration, afc.reachedAngle))
        }
    }
    
    // MARK: - Local Notifications extension
    //when the user receives a local notification regarding an ended timer and tapersistentStore on the notification, he probably wants to get to that timer
    var userTouchedNotification : (timerID:String?, restart:Bool?) {didSet{
        showTimerAndRestartIfAsked()
    }}
    
    // MARK: - little helpers
    ///I dont like how tableview looks like on phones with a notch
    fileprivate func fixTableViewTopContentInset() {
        //make table view look pretty especially for the phones with notch
        let sbHeight = SceneDelegate.statusBarManager?.statusBarFrame.height ?? 0
        let shouldIChangeInset = sbHeight > 30
        
        tableView.contentInset =
            UIEdgeInsets(top: shouldIChangeInset ? 0.79 * sbHeight : sbHeight , left: 0, bottom: 0, right: 0)
    }
    
    ///used by leadingSwipe and in setDDS
    let durationColors = [ "Silver":UIColor.white ]
    
    func durationDisplayColor(for timer:CT) -> UIColor {
        guard timer.isTimer, let color = timer.color
        else { return UIColor() }
        
        return durationColors[color] ?? .white
    }
}

extension CTTVC:NSFetchedResultsControllerDelegate { }

// MARK: - Data Source
extension CTTVC {
    /* these functions attached here instead of implemented in the CTCell. it would have been a nightmare to do so.. */
    fileprivate func triggerScaleAnimation(_ button: SecondsButton) {
        UIView.animate(withDuration: 0.1) {
            button.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        } completion: { succes in
            button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    @objc
    func secondsButtonTapped(button: SecondsButton) {
        //make sure scale animation does not cause cell to appear cutoff
        if let cell = getCell(for: button) { tableView.bringSubviewToFront(cell) }
        
        let bubble = frc.object(at: IndexPath(row: button.tag, section: 0))
        startPause(bubble)
    }
    
    func start(_ isStart:Bool, _ bubble:CT) {
        
        handleNotification(isStart ? .start : .pause, for: bubble)
        
        switch isStart {
        case true: /* start */
            bubble.run(.user)
            syncMarble(of:bubble, for:.userStart)
            
        case false: /* pause */
            bubble.pause(.user)
            syncMarble(of: bubble, for:.userPause)
        }
        
        //UI stuff
        guard
            let indexPath = frc.indexPath(forObject: bubble),
            let cell = tableView.cellForRow(at: indexPath) as? CTCell
        else {return}
        
        //UI stuff
        if bubble.isTimer {
            if bubble.userNeedle <= 0 {
                showDoneSticker(show: true, for: cell)
                return
            }
        }
        
        //UI stuff
        triggerScaleAnimation(cell.secondsButton)
        UserFeedback.triggerSingleHaptic(.heavy)
        cell.startSticker.alpha = (bubble.state == .running) ? 0 : 1
    }
    
    func startNotificationTap(_ timer:CT) { start(true, timer) }
    
    // MARK: -
    fileprivate func animateTimeLabelsForEndSession(_ subviews: [UIView]) {
        for index in 0..<subviews.count {
            let scale =  1.15 - (0.8 * CGFloat(index))
            UIView.animate(withDuration: 0.1) {
                subviews[index].transform = CGAffineTransform(scaleX: scale, y: scale)
            } completion: { succes in
                subviews[index].transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }
    }
    
    fileprivate func showDoneSticker(show:Bool, for cell:CTCell) {
        cell.doneSticker.alpha = show ? 1 : 0
//        cell.coverTimeComponents(show ? true : false)
    }
    
    @objc
    func secondsButtonPressed(gesture:LongPress) {
        if gesture.state == .began {
            guard
                let buttonTag = (gesture.view as? SecondsButton)?.tag
            else {fatalError()}
            
            //make sure scale animation does not cause cell to appear cutoff
            if let cell = getCell(for: buttonTag) { tableView.bringSubviewToFront(cell) }
            
            hintViewManager.removeHintViewIfNeeded()
            
            let bubble = frc.object(at: IndexPath(row: buttonTag, section: 0))
            
            if bubble.state != .brandNew {
                //show undoSaveHintView
                getCell(for: buttonTag)?.showUndoSaveHint(true)
                //store tuple
                undoSave_IndexPathDate_Tuples.append((IndexPath(row: buttonTag, section: 0), Date()))
            }
            
            bubble.currentClock = bubble.referenceClock /* ⚠️ not really right.. */
            
            bubble.sessionEndedByUser = true
            endSession(bubble)
        }
    }
    
    ///edit duration of a timer right inside CTTVC
    @objc func handleDoubleTap(_ gesture:UITapGestureRecognizer) {
    /*
        when user double taps cell.hoursLabel, editVC shows up
        */
    
    if gesture.state == .ended {
        guard
            let cell = gesture.view?.superview?.superview?.superview as? CTCell
        else { fatalError() }
                    
        if cell.isSelected { cell.isSelected = false }
        
        var delay:DispatchTime = .now()
        
        let sbHeight = ViewHelper.statusBarHeight()
        let condition = cell.absoluteFrame().origin.y < sbHeight
        
        //⚠️ make sure first cell is fully onscreen
        if !cell.isFullyVisibleOnscreen || condition {
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            delay = .now() + 0.3
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
        
        delayExecution(delay) { [weak self] in
            self?.performSegue(withIdentifier: "toEditDurationVC", sender: cell)
        }
        
        UserFeedback.triggerSingleHaptic(.heavy)
    }
}
    
    @objc func handleSwipeLeft(_ swipe:UISwipeGestureRecognizer) {
        if swipe.state == .ended {
            guard let cell = swipe.view as? CTCell else { fatalError() }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: []) {
                cell.transform = CGAffineTransform(translationX: -cell.swipeTranslation, y: 0)
            } completion: { _ in
            }
        }
    }
    
    func  endSession(_ bubble:CT) {
        //        updateWidget(for: timeBubble, .userEndSession)
        /* do this before you change state below */
        if bubble.state == .running { handleNotification(.endSession, for:bubble) }
        
        bubble.endCurrentSession() /* model */
        if !bubble.bubbleSessions.isEmpty && bubble.isCalendarEnabled {
            CalManager.shared.createNewEvent(for: bubble.currentSession!)
        }
        
        /* 📺 2.UI part + notifications */
        guard
            let indexPath = frc.indexPath(forObject: bubble),
            let cell = tableView.cellForRow(at: indexPath) as? CTCell
        else {return}
        
        if bubble.isTimer {
            syncMarble(of:bubble, for:.initial)
            cell.doneSticker.alpha = 0
            showDoneSticker(show: false, for: cell)
        }
        
        UserFeedback.triggerDoubleHaptic(.heavy)
        
        // FIXME: - visual feedback (animation)
        let subviews = cell.secondsButton.superview!.subviews
        animateTimeLabelsForEndSession(subviews)
        cell.startSticker.alpha = 1
        
        if bubble.hasSquareWidget {
            cell.shapeShift(.square())
        }
    }
}

// MARK: - Delegate
extension CTTVC {
    override func tableView(_ tableView: TV, heightForRowAt indexPath: IP) -> CGFloat {
        return rowHeight
    }

    private struct RowSelection {
        static var touchedRows = [Int]() {didSet{
            selectionStyleIsNone = false
            if !touchedRows.isEmpty && touchedRows.count >= 2 {
                if touchedRows.last! != touchedRows[touchedRows.count - 2] {
                    touchedRows = [touchedRows.last!]
                    selectionStyleIsNone = false
                } else {
                    selectionStyleIsNone = (touchedRows.count%2 == 0) ? true : false
                }
            }
        }}
        static var selectionStyleIsNone = false
    }
    
    override func tableView(_ tableView: TV, willSelectRowAt indexPath: IP) -> IP? {
        
        hintViewManager.removeHintViewIfNeeded()
        
        let cell = tableView.cellForRow(at: indexPath)!
        RowSelection.touchedRows.append(indexPath.row)
        if RowSelection.selectionStyleIsNone { cell.selectionStyle = .none }
        else { cell.selectionStyle = .default }
        
        return indexPath
    }
    
    override func tableView(_ tableView: TV, willDisplay cell: UITableViewCell, forRowAt indexPath: IP) {
        
        //marble for timers
        let bubble = frc.object(at:indexPath)
        
        if bubble.isTimer {
            //⚠️ sync marbles only if it's not app's first launch
            if Date().timeIntervalSince(AppDelegate.appLaunchDate) > 0.3 {
                delayExecution(.now() + 0.05) {
                    [weak self] in
                    self?.syncMarble(of:bubble, for:.tableViewWillDisplayCell)
                }
            }
            
            //displayed duration in small fonts for timers
            if bubble.durationVisible {
                let color = durationDisplayColor(for: bubble)
                (cell as? CTCell)?.durationHoursLabel.textColor = color
                (cell as? CTCell)?.durationMinutesLabel.textColor = color
                (cell as? CTCell)?.durationSecondsLabel.textColor = color
            }
        }
    }
}

extension CTTVC {
    func getCell(for button:UIButton) -> CTCell? {
        tableView.cellForRow(at: IndexPath(row: button.tag, section: 0)) as? CTCell
    }
    
    func getCell(for index:Int?) -> CTCell? {
        guard let index = index else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CTCell
    }
}

extension CTTVC:ChronoTimerCellDelegate {
    func undoLastActionTapped(_ button: UIButton) {
        deleteMostRecentSession(at: IndexPath(row: button.tag, section: 0))
    }
    
    func calendarStickerTapped(cellIndex index: Int) {
        let ct = frc.object(at: IndexPath(row: index, section: 0))
        
        //model
        switch ct._calendarStickerState {
        case .fullyDisplayed: ct._calendarStickerState = .minimized
        case .minimized: ct._calendarStickerState = .fullyDisplayed
        default: break
        }
        CoreDataStack.shared.saveContext()

        //UI
        let cell = getCell(for: index)
        cell?.setupCalendarSticker(for: ct, animated: true)
    }
    
    func hoursLabelPressed(cellIndex index: Int) {
        
        let ct = frc.object(at: IndexPath(row: index, section: 0))
        
        //model
        //store user preference
        ct.stickyNoteVisible = !ct.stickyNoteVisible
        
        //UI
        //hide or show sticky note
        let cell = getCell(for: index)
        cell?.hide(ct.stickyNoteVisible ? false : true, cell?.stickyNote, scaleAnimate: true)
        cell?.setupCalendarSticker(for: ct, animated: true)
        
        //show keybrd is sticky note is empty
        if ct.stickyNote.isEmpty {
            if ct.stickyNoteVisible { cell?.stickyNote.field.becomeFirstResponder() }
            else { cell?.stickyNote.field.resignFirstResponder() }
        }
        else { UserFeedback.triggerSingleHaptic(.soft) }
    }
    
    func userResignedFirstResponder(cellIndex index:Int, fieldText:String) {
        let newSticky = fieldText
        
        let bubble = bubble(at: IndexPath(row: index, section: 0))
        let oldSticky = bubble.stickyNote
        
        if newSticky != oldSticky {
            addStickyToChronoTimer(cellIndex:index, text:fieldText)
            delayExecution(.now() + 0.1) {[weak self] in
                self?.notificationsManager.updateStickyNoteInNotification(for: bubble)
                if let count = bubble.sessions?.count, count > 0 {
                    CalManager.shared.updateExistingEvent(.title(bubble))
                }
            }
        }
    }
    
    func animationStopped(cellIndex index: Int, flag: Bool) {
        
        /* need to update marble's position */
        if let cell = getCell(for: index) {
            let indexPath = IndexPath(row: cell.secondsButton.tag, section: 0)
            let bubble = frc.object(at: indexPath)
            
            /* it stopped because it finished normally */
            if flag { syncMarble(of:bubble, for:.initial) }
        }
    }
    
    // MARK: - handle sticky
    private func addStickyToChronoTimer(cellIndex:Int, text:String) {
        let ct = frc.object(at: IndexPath(row: cellIndex, section: 0))
        ct.stickyNote = text
        CoreDataStack.shared.saveContext()
    }
}

// MARK: - receiving and handling notifications
extension CTTVC {
    /*
     running timeBubbles only! ⚠️
     1. resume running any running cts (ct.state == running)
     2. register onlineAt. use to compute online duration when the app quits or enters background
     */
    /// called by SceneDelegate regardless if 1.app was killed and reopened or 2.it was in the background
    func prepareCTsForOnline() {
        guard frc?.fetchedObjects != nil else {return}
        
        frc.fetchedObjects?.forEach {
            if $0.state == .running {
                killTimerIfNeeded($0)
                syncMarble(of:$0, for:.enterOnline)
                $0.run(.system)
            }
        }
    }
    
    func shouldKill(_ timer:CT) -> Bool {
        guard
            let lastStart = timer.currentSession?._pairs.last?.start
        else { return false }
        
        return Date().timeIntervalSince(lastStart) >= TimeInterval(timer.currentClock)
    }
    
    private func killTimerIfNeeded(_ timer:CT) {
        
        guard timer.isTimer,
              timer.state == .running
        else { return }
                        
        if shouldKill(timer) {
            //Model
            timer.declareZeroTimer()
            
            //UI stuff
            guard
                let indexPath = frc.indexPath(forObject: timer),
                let cell = tableView.cellForRow(at: indexPath) as? CTCell
            else {return}
            
            self.updateTimeComponents(of: cell, for: 0)
            
            cell.hide(false, cell.doneSticker)
            self.syncMarble(of:timer, for:.initial)
            
            if cell.secondsButton.pauseSticker.isVisible { cell.hidePauseSticker(true) }
        }
    }
    
    private func sysPauseAllRunning() {
        guard let bubbles = frc.fetchedObjects else {return}
        bubbles.forEach {
            /* system means state will not change, so it will stay running */
            if $0.state == .running { $0.pause(.system) }
        }
    }
    
    //register as observer
    private func registerFor_DidEnterBackground() {
        NC.default.addObserver(forName: Post.didEnterBackground, object: nil, queue: nil) {
            [weak self] _ in
            self?.sysPauseAllRunning()
            /* context will be saved */
        }
    }
    
    private func register_For_NeedleUpdate() {
        /* CT posts notification when needle update has new value */
        NotificationCenter.default.addObserver(forName: Post.needleUpdated, object: nil, queue: nil) {
            [weak self] notification in
            guard
                let self = self,
                let bubble = notification.object as? CT,
                let userNeedle = notification.userInfo?["needle"] as? Int
            else {return}
            
            self.updateCellUI(for:bubble, and:userNeedle)
        }
    }
    
    private func registerFor_repeatTimerWhenYouWakeUp () {
        let name = NSNotification.Name("repeatTimerWhenYouWakeUp")
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) {
            [weak self] notification in
            guard
                let self = self,
                let timerID = notification.userInfo?["timerID"] as? String
            else {return}
            
            self.id_ofTimer_EagerToRepeat = timerID
        }
    }
    
    //registerFor_TexfieldDidBeginEditing
    
    //registerFor_KeyboardFrame_Updates
    
    //1▶︎ make sure keyboard hidden in CTTVC
    private func registerFor_WillResignActive() {
        
        /* use it to make sure no keyboard is alive! */
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) {
            [weak self] _ in
            guard let self = self else { return }
            
            /* ------------- WIDGETS */
            //widgets: keeping widgets in sync with the time bubbles
            self.frc.fetchedObjects?.forEach {
                self.updateWidget(for: $0)
            }
            
            //round widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "RoundWidget")
            /* ------------- WIDGETS */
            
            //keyboard
            if self.tableViewWentUpToShowTextField {
                //you may want to change that in the future so better put here a guard statement
                guard self.tableView.visibleCells.count == 4 || self.tableView.visibleCells.count == 5 else { return }
                
                if self.tableView.transform != .identity {
                    self.tableView.endEditing(true)
                    self.tableView.transform = .identity
                }
                
                //⚠️ no idea why that works but if field of last and penultimate stickyNotes disabled long enough, will prevent tableView to descend too much and look ugly!
                (self.tableView.visibleCells.last as? CTCell)?.stickyNote.field.isUserInteractionEnabled = false //last field
                (self.tableView.visibleCells.penultimate as? CTCell)?.stickyNote.field.isUserInteractionEnabled = false //penultimate field
                
                self.tableViewWentUpToShowTextField = false
                
                delayExecution(.now() + 2.0) {[weak self] in
                    self?.tableView.visibleCells.forEach { ($0 as? CTCell)?.stickyNote.field.isUserInteractionEnabled = true }
                }
            }
        }
    }
    
    private func registerFor_DidBecomeActive() {
        let name = UIApplication.didBecomeActiveNotification
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) {
            [weak self] _ in
            self?.matchBubblesToSquareWidgets()
        }
    }
    
    // MARK: - helper
    private func updateTimeComponents(of cell:CTCell, for value:Int) {
        cell.secondsButton.setTitle(String(value.time().sec), for: .normal)
        cell.minutesLabel.text = String(value.time().min)
        cell.hoursLabel.text = String(value.time().hr)
    }
    
    ///updateCellUI called every second. when a timer is in editMode, time components do not need update, since the user does not see them. ⚠️ However doneSticker must be updated regardless if editMode is ON or OFF
    private func updateCellUI(for bubble:CT, and userNeedle:Int) {
        if bubble.state != .brandNew {
            self.checkAndEndAnyZeroTimers(userNeedle, bubble)
        }
        
        guard let index = self.frc?.indexPath(forObject: bubble)?.row else { return }
        
        ///chronoTimer's needle
        let totalSeconds = userNeedle
        
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CTCell
        
        /* ⚠️ even if cell in editMode show doneSticker for zero timer */
        if bubble.isTimer && bubble.currentClock <= 0 {
            cell?.hide(false, cell?.doneSticker)
            cell?.hide(true, cell?.startSticker)
        }
                
        /* time components */
        let time = totalSeconds.time()
        
        if cell?.hoursLabel.text != String(time.hr) {
            cell?.hoursLabel.text = String(time.hr)
        }
        
        if cell?.minutesLabel.text != String(time.min)
            && cell?.minutesLabel.text != nil {
            cell?.minutesLabel.text = String(time.min)
        }
        cell?.secondsButton.setTitle(String(totalSeconds.time().sec), for: .normal)
        
        // FIXME:
        /* reset reused cells before if condition evaluated */
        cell?.minutesLabel.alpha = 1
        
        cell?.invisibleHoursLabel(false)
        
        if !bubble.isTimer {
            let minutesCondition = (totalSeconds.time().min < 1) && totalSeconds < 60
            let hoursCondition = (totalSeconds.time().hr < 1) && totalSeconds < 3600
            cell?.minutesLabel.alpha = minutesCondition ? 0 : 1
            
            if cell?.hoursLabel.color != .clear {//ok here
                cell?.invisibleHoursLabel(hoursCondition ? true : false)
            }
        }
        
        /* minutes label jumps at one minute */
        /* 1 minute - 1 sec */
        if !bubble.isTimer , totalSeconds == 59 {
            if let amIOnScreen = cell?.isOnscreen, amIOnScreen {//don't animate if cell is not onscreen
                cell?.minutesLabel.layer.add(CAKeyframeAnimation.horizontalWobble(duration: 1.5), forKey: "wobble x")
                cell?.minutesLabel.layer.add(CAKeyframeAnimation.alpha(color: cell?.minutesLabel.color ?? UIColor.gray, duration: 0.5), forKey: "color")
            }
        }
        
        /* hour label jumps at one hour */
        /* at 3599 seconds (1 hour - 1 sec) */
        if !bubble.isTimer , totalSeconds == 59*60 + 59 {
            delayExecution(.now() + 1.0) { cell?.invisibleHoursLabel(false) }
            
            if let amIOnScreen = cell?.isOnscreen, amIOnScreen {//don't animate if cell is not onscreen
                cell?.hoursLabel.layer.add(CAKeyframeAnimation.horizontalWobble(duration: 1.5), forKey: "wobble x")
                cell?.hoursLabel.layer.add(CAKeyframeAnimation.alpha(color: cell?.hoursLabel.color ?? UIColor.gray, duration: 0.5), forKey: "color")
            }
        }
    }
}

// MARK: - 1▶︎ avoid keyboard covering cell's sticky note
extension CTTVC {
    
    private func registerFor_TexfieldDidBeginEditing() {
        let nc = NotificationCenter.default
        let post = Post.textFieldDidBeginEditing
        nc.addObserver(forName: post, object: nil, queue: nil) {
            [weak self] notification in
            guard
                let self = self,
                let cell = ((notification.object as? StickyNote)?.superview?.superview as? CTCell)
            else { return }
            
            self.cellBoundsInTableViewCoordinateSpace = cell.convert(cell.bounds, to: nil) /* ⚠️ bounds not frame! */
        }
    }
    
    private func registerFor_KeyboardFrame_Updates() {
        let center = NotificationCenter.default
        let willChangeFrame = UIResponder.keyboardWillChangeFrameNotification
        center.addObserver(self, selector: #selector(adjustViewForKeyboard), name: willChangeFrame, object: nil)
    }
    
    @objc private func adjustViewForKeyboard(notification:Notification) {
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardFrame = (notification.userInfo![key] as? CGRect) else {return}
        /* keyboard frame. originY increases when keyboard goes away in such a way that the origin is at bottom left of the screen, maybe before it goes away.. */
        
        if keyboardFrame.origin.y < UIScreen.main.bounds.height {//keyboard is expanded. it shows onscreen
            guard let cellBounds = cellBoundsInTableViewCoordinateSpace else { return }
            
            let obscureAmount = (cellBounds.origin.y + cellBounds.size.height) - keyboardFrame.origin.y
            if obscureAmount > 0 {
                if obscureAmount > 4 { tableViewWentUpToShowTextField = true }
                //table view must go up by keyboard.height :)
                tableView.transform = CGAffineTransform(translationX: 0, y: -obscureAmount)
            }
        }
        else { tableView.transform = .identity }
    }
}

// MARK: -
class DataSource: CTTVC.DDS {
    //for this app it shows delete action when user swipes left on a row
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
}

// MARK: - organize
extension CTTVC {
    ///make sure zeroTimers have their currentSession set to ended
    func shouldEndCurrentSession(for timer:CT) {
        guard
            timer.isTimer,
            timer.state != .brandNew
        else { return }
        
        if timer.state == .zeroTimer && timer.currentSession != nil {
            if !timer.currentSession!.isEnded {
                timer.currentSession?.isEnded = true
            }
        }
        CoreDataStack.shared.saveContext()
    }
}

// TODO: find better name for the method
// MARK: - handle Widgets
extension CTTVC {
    func handleURLHost(_ id:String) {
        //identify timeBubble
        guard
            let bubble = bubble(for: id),
            let indexPath = frc.indexPath(forObject: bubble)
        else { return }
        
        //scroll to that cell
        scrollAndSelectBubble(at: indexPath)
    }
    
    ///stores ID of running time bubbles, so that the bolt widget knows which time bubble to track
    internal func storeInSharedFolder(_ bubble:CT) {
        //only for time bubbles that do not have a widget
        guard
            bubble.state == .running,
            !bubble.hasSquareWidget,
            let id = bubble.id?.uuidString
        else { return }
        
        let sharedFile = FileManager.sharedFolder.appendingPathComponent("latestStartedTimeBubbleID")
        do {
            try id.write(to: sharedFile, atomically: true, encoding: .utf8)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

// MARK: - little helpers
extension CTTVC {
    //reverse order for long hours https://share.icloud.com/photos/0xfgc4qzqSyOeX6TL53fZPFMw
    func ifNeededDisplayTimeComponentsInReverseOrder(for cell:CTCell) {
        delayExecution(.now() + 0.3) {
            //there has to be a slight delay otherwise, maybe because of the animation duration, it takes a little time
            //for the time components to have the correct values
            guard let count = cell.hoursLabel.text?.count, count >= 3 else { return }
            
            //hours label moves in front of minutes and seconds. minutes label moves in front of seconds button
            cell.hoursLabel.layer.zPosition = 2
            cell.minutesLabel.layer.zPosition = 1
        }
    }
}

// MARK: -
extension CTTVC {
    ///⚠️  timer duration saved only when the user is actually using the value. Timers only!
    func saveTimerDuration(for timer:CT) {
        guard
            timer.isTimer,
            timer.state == .brandNew,
            timer.referenceClock != timer.lastUsedTimerDuration
        else { return }
        
        let newTimerDuration = TimerDuration(context: AppDelegate.context)
        newTimerDuration.date = Date()
        newTimerDuration.id = timer.id?.uuidString
        newTimerDuration.duration = timer.referenceClock
        timer.lastUsedTimerDuration = newTimerDuration.duration
        newTimerDuration.color = timer.color
        // ⚠️ do NOT set timer property: newTimerDuration.timer = self

        
        if timer.timerDurationsArray.count >= CT.recentlyUsedDurationsLimit {
            let array = timer.timerDurationsArray
            timer.removeFromTimerDurations(array.last!)
        }
        
        if !timer.durationIsUnique(newTimerDuration.duration) {
            //remove the value in the array before adding the latest
            guard
                let duplicateDuration = timer.timerDurationsArray.filter({ $0.duration == newTimerDuration.duration }).first
            else { fatalError() }
            
            timer.removeFromTimerDurations(duplicateDuration)
        }
        
        timer.addToTimerDurations(newTimerDuration)
        
        CoreDataStack.shared.saveContext()
    }
}
