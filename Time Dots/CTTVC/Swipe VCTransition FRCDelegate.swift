/*
 ⚠️
 if you use didChangeContentWith method, not other delegate methods will be called.
 1.fResultsController is the source of truth and always up-to-date. it represents the future
 2.snapshot is something weird. it's a "reference snapshot" whatever that is.. but it has the future content as well
 3.dds.snapshot is the NOT up-to-date snapshot. it represents the past
 */

import UIKit
import CoreData
import WidgetKit

extension CTTVC { typealias Action = UIContextualAction }

// MARK: - right and left swipes
extension CTTVC {
    override func tableView(_ tableView: TV, leadingSwipeActionsConfigurationForRowAt indexPath: IP) -> ActionsConfig? {
        
        let bubble = self.frc.object(at: indexPath)
        
        //action 0: more options
        let moreOptionsAction = Action(style: .normal, title: "More") {
            (action, swipeActionButton, completion) in
            
            completion(true) //cell shifts back automatically
            
            //it shows a new VC
            let moreOptionsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "moreOptionsVC") as! MoreOptionsVC
            
            //Data sent to MoreOptionsVC ⬇
            moreOptionsVC.indexPath = indexPath
            moreOptionsVC.isTimer = bubble.isTimer
            moreOptionsVC.initialColorName = bubble.color
            
            if bubble.isTimer {
                //if it's a timer make sure to set the correct title for the button
                moreOptionsVC.showHideDurationButton_Title = bubble.durationVisible ? "Hide Duration" : "Show Duration"
                
            } else {
                //if it's not a timer, hide the buttons stack entirely
                moreOptionsVC.shouldButtonsStackBeHidden = true
            }
            
            if let subtitle = !bubble.stickyNote.isEmpty ? bubble.stickyNote : bubble.color {
                moreOptionsVC.showHideDurationButton_Subtitle = subtitle
            }
            
            let bubble = self.frc.object(at: indexPath)
            moreOptionsVC.bubbleID = bubble.id?.uuidString
            moreOptionsVC.timerReferenceClock = bubble.referenceClock
            //⬆
            
            delayExecution(.now() + 0.05) {[weak self] in
                self?.present(moreOptionsVC, animated: true)
            }
        }
        
        let calendarEnabled = bubble.isCalendarEnabled
        
        //action 2: enable calendar
        let enableCalendarAction = Action(style: .normal, title: !calendarEnabled ? "Cal On" : "Cal Off") {
            (action, swipeActionButton, completion) in
            guard
                let cell = tableView.cellForRow(at: indexPath) as? CTCell
            else {return}
            
            if UserDefaults.standard.value(forKey: UDKey.calendarAuthorizationRequestedAlready) == nil {
                CalendarEventsManager.shared.requestAuthorizationAndCreateCalendar()
                UserDefaults.standard.setValue(true, forKey: UDKey.calendarAuthorizationRequestedAlready)
            }
            
            UserFeedback.triggerSingleHaptic(.medium)
            completion(true)
            
            //model
            bubble._isCalendarEnabled = !bubble._isCalendarEnabled
            CoreDataStack.shared.saveContext()
            
            
            //UI
            cell.stickyNote.slidingBackground.color = bubble.isCalendarEnabled ? #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1) : cell.nonCalendarColor
            cell.setupCalendarSticker(for: bubble, animated: true)
            
            //exports only if calendar is enabled
            CalendarEventsManager.shared.shouldExportToCalendarAllSessions(of: bubble)
        }
        
        moreOptionsAction.image = UIImage(systemName: "ellipsis.circle.fill")?.ofSize(CGSize(width: 800, height: 800), .white)
        moreOptionsAction.backgroundColor = UIColor(named: "moreOptionsAction")
        
        //combine images for CalON and CallOFF
        //803 × 738
        let size = CGSize(width: 870, height: 738) //make sure aspect ratio is good
        let calendar = UIImage(systemName: "calendar")!.withTintColor(.white)
        let checkmark = UIImage(systemName: "checkmark")!
        
        let checkmarkColor = UIColor(named: "Confirm") ?? .black
        let calONImage = calendar.combine(with: checkmark, color: checkmarkColor, in: size)
        
        let cancel = UIImage(systemName: "line.diagonal")!
        let calOFFImage = calendar.combine(with: cancel, of: 1, color: .red, in: size)
        
        let image = !calendarEnabled ? calONImage : calOFFImage
        //set image
        enableCalendarAction.image = image
        
        let name = !calendarEnabled ? "calendarON" : "calendarOFF"
        let color = UIColor(named: name)
        enableCalendarAction.backgroundColor = color
        
        let config = SwipeConfiguration(actions: [moreOptionsAction, enableCalendarAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    override func tableView(_ tableView: TV, trailingSwipeActionsConfigurationForRowAt indexPath: IP) -> ActionsConfig? {
        
        let bubble = frc.object(at: indexPath)
        let sessionsCount = bubble.bubbleSessions.count
        let cell = tableView.cellForRow(at: indexPath) as! CTCell
        
        let undoSaveAction = Action(style: .destructive, title: "Undo\nSave") {
            [weak self] (action, view, completion) in
            
            self?.deleteMostRecentSession(at: indexPath)
            view.isUserInteractionEnabled = false
            
            //show checkmark and done
            let doneView = DoneView()
            let bounds = CGRect(origin: .zero, size: CGSize(width: 2*view.bounds.width, height: view.bounds.height))
            doneView.frame = bounds
            
            doneView.sessionCount = sessionsCount - 1
            doneView.sessionCountBackgroundColor = UIColor(named: "showHistoryAction")
            
            view.addSubview(doneView)
            view.clipsToBounds = false
            view.layer.zPosition = 100
            view.superview?.subviews.forEach({ $0.isUserInteractionEnabled = false })
            
            self?.getCell(for: indexPath.row)?.showUndoSaveHint(false)
            
            if let tuple = self?.undoSave_IndexPathDate_Tuples.filter ({ $0.indexPath == indexPath }).first {
                self?.undoSave_IndexPathDate_Tuples.removeAll { $0 == tuple }
            }
            
            UserFeedback.triggerSingleHaptic(.heavy)
            delayExecution(.now() + 0.6) {
                completion(true) /* will bounce back after handler completes */
            }
        }
        
        let deleteAction = Action(style: .normal, title: "•••") {
            [weak self] (action, view, completion) in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let deleteActionVC = storyBoard.instantiateViewController(withIdentifier: DeleteActionVC.id) as? DeleteActionVC else { return }
            
            //payload
            deleteActionVC.bubbleID = self?.frc.object(at: indexPath).id?.uuidString
            deleteActionVC.bubbleIndexPath = indexPath
            deleteActionVC.sessionsCount = sessionsCount
            deleteActionVC.bubbleColor = bubble.color
            deleteActionVC.bubbleDescription = bubble.kindDescription
            
            let cellFrame = self?.getCell(for: indexPath.row)?.absoluteFrame()
            deleteActionVC.cellFrame = cellFrame
            
            deleteActionVC.centerY = self?.getCell(for: indexPath.row)?.absoluteCenter().y
            //present
            self?.present(deleteActionVC, animated: false)
            UserFeedback.triggerSingleHaptic(.medium)
            
            completion(true) /* will bounce back after handler completes */
        }
        
        let showHistoryAction =  Action(style: .normal, title: "History") {
            [weak self] (action, /*swipe action*/swipeActionButton, completion) in
            guard let self = self else {return}
            
            /* will bounce back after handler completes */
            completion(true)
            
            if let cell = tableView.cellForRow(at: indexPath) as? CTCell {
                self.performSegue(withIdentifier: Segue.toDetailVC, sender: cell)
            }
        }
        
        undoSaveAction.image = UIImage(named: "undo")
        undoSaveAction.backgroundColor = UIColor(named: "undoLastAction")
        
        deleteAction.image = UIImage(named: "trashBubble")
        
        //history image
        let image = UIImage(named: String(sessionsCount))
        showHistoryAction.image = image
        deleteAction.backgroundColor = UIColor(named: "deleteAction")
        
        showHistoryAction.backgroundColor = UIColor(named: "showHistoryAction")
        
        //default actions
        var actions = [showHistoryAction, deleteAction]
        if !cell.undoSaveHint.isHidden { cell.undoSaveHint.isHidden = true }
        
        if let tuple = undoSave_IndexPathDate_Tuples.filter ({ $0.indexPath == indexPath }).first {
            if abs(tuple.date.timeIntervalSinceNow) <= undoLastActionDuration, bubble.state != .running {
                cell.undoSaveHint.isHidden = true
                actions = [showHistoryAction, undoSaveAction]
            }
        }
        
        if !undoSave_IndexPathDate_Tuples.isEmpty {
            undoSave_IndexPathDate_Tuples.removeAll { abs($0.date.timeIntervalSinceNow) > undoLastActionDuration }
        }
        
        let config = SwipeConfiguration(actions: actions)
        
        return config
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if let indexPath = indexPath {
            let cell = tableView.cellForRow(at: indexPath) as? CTCell
            
            //secondary
            let isFiveSecondsTimerActive = cell?.fiveSecondsTimer?.isValid ?? false
            func showUndoSaveHint() { cell?.undoSaveHint.isHidden = false }
            
            //main
            if isFiveSecondsTimerActive { showUndoSaveHint() }
        }
    }
        
    //helpers
    ///undo last save action
    internal func deleteMostRecentSession(at indexPath:IP) {
        let bubble = frc.object(at: indexPath)
        let session = bubble.sessions?.lastObject as? Session
        guard
            session?.totalDuration() != nil,
            let session = session else { return }
        
        if bubble.isCalendarEnabled {
            //remove calendar event
            CalendarEventsManager.shared.deleteEvent(with:session.eventID)
        }
        
        AppDelegate.context.delete(session)
        CoreDataStack.shared.saveContext()
    }
    
    func deleteBubble(at indexPath:IP) {
        /*
         1.delete items through core data
         2.save context
         3.frc.delegate method will notify of the changes
         and new snapshot will be applied ??
         */
        
        let bubble = frc.object(at: indexPath)
        
        /* first cancel notification then change state! */
        handleNotification(.delete, for:bubble)
        notificationsManager.removeDeliveredAndPendingNotifications(for: bubble) //both pending and delivered!
                
        AppDelegate.context.delete(self.frc.object(at: indexPath))
        CoreDataStack.shared.saveContext()
        
        delayExecution(.now() + 0.5) {
            WidgetCenter.shared.reloadTimelines(ofKind:"SquareWidget")
        }
    }
    
    func eraseHistoryForBubble(at indexPath:IP) {
        /*
         1.if 1.state is brandnew AND 2.no sessions, it will not recycle
         2.cancel any notification
         3.end session
         4.delete all timeBubble's sessions
         5.reset marble to zero angle
         6.save context with slight delay (no idea why that is :)))
         */
        
        let bubbleToRecycle = frc.object(at: indexPath)
        /* 1 */if bubbleToRecycle.state == .brandNew && bubbleToRecycle.bubbleSessions.isEmpty { return }
        /* 2 */handleNotification(.delete, for:bubbleToRecycle)
        /* 3 */bubbleToRecycle.endCurrentSession()
        
        //delete all sessions
        if let sessions = bubbleToRecycle.sessions?.array as? [Session] {
            /* 4 */sessions.forEach { AppDelegate.context.delete($0) }
        }
        
        //UI part
        //since time bubbles are recycled, corresponding cells must have startSticker visible and timers doneSticker hidden
        let cell = getCell(for: indexPath.row)
        if bubbleToRecycle.isTimer {
            cell?.doneSticker.alpha = 0
        }
        //        cell?.startLine.alpha = 1.0
        cell?.startSticker.alpha = 1
        
        /* 5 */syncMarble(of:bubbleToRecycle, for:.initial)
        
        //Save context part
        /* 6 */delayExecution(.now() + 0.1) { CoreDataStack.shared.saveContext() }
        
        //make sure timeComponents are all visible
        // FIXME: is not declared zeto timer!!!
        if bubbleToRecycle.isTimer { cell?.coverTimeComponents(false) }
        if bubbleToRecycle.state == .zeroTimer {
            
        }
    }
    
    private func eraseHistoryImage(_ sessionsCount:Int) -> UIImage {
        UIImage(systemName: "\(String(sessionsCount)).circle.fill") ?? UIImage()
    }
    
    @available(iOS 10.0, *)
        private func addLabelToImage(image: UIImage, label: UILabel) -> UIImage? {
            let tempView = UIStackView(frame: CGRect(x: 0, y: 0, width: 90, height: 50))
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.height))
            imageView.contentMode = .scaleAspectFit
            tempView.axis = .vertical
            tempView.alignment = .center
            tempView.spacing = 8
            imageView.image = image
            tempView.addArrangedSubview(imageView)
            tempView.addArrangedSubview(label)
            let renderer = UIGraphicsImageRenderer(bounds: tempView.bounds)
            let image = renderer.image { rendererContext in
                tempView.layer.render(in: rendererContext.cgContext)
            }
            return image
        }
    
    //MoreOptionsVC calls it if the user touches "Show/Hide Duration" button
    func toggleDuration(for indexPath:IndexPath?) {
        guard
            let indexPath = indexPath,
            let cell = tableView.cellForRow(at: indexPath) as? CTCell
        else { return }
        
        let bubble = self.frc.object(at: indexPath)
        
        bubble.durationVisible = !bubble.durationVisible
        CoreDataStack.shared.saveContext()
        
        cell.durationHoursLabel.alpha = bubble.durationVisible ? 1 : 0
        cell.durationMinutesLabel.alpha = bubble.durationVisible ? 1 : 0
        cell.durationSecondsLabel.alpha = bubble.durationVisible ? 1 : 0
        
        if bubble.durationVisible {
            let time = Int(bubble.referenceClock).time()
            cell.durationHoursLabel.text = String(time.hr)
            cell.durationMinutesLabel.text = String(time.min)
            cell.durationSecondsLabel.text = String(time.sec)
        }
        
        //set color to white if timeBubble color is charcoal, white if other colors
        let color = self.durationDisplayColor(for: bubble)
        cell.durationHoursLabel.textColor = color
        cell.durationMinutesLabel.textColor = color
        cell.durationSecondsLabel.textColor = color
    }
    
    func changeColor(to newColor:String?, at indexPath:IndexPath?) {
        guard let indexPath = indexPath else { return }
        
        let bubble = self.frc.object(at: indexPath)
        
        bubble.color = newColor
        CoreDataStack.shared.saveContext()
        
        notificationsManager.updateTimerColorInNotification(for: bubble)
        
        var currentSnapshot = dds.snapshot()
        currentSnapshot.reloadItems([bubble])
        dds.apply(currentSnapshot, animatingDifferences: false)
    }
}

// MARK: - Edit Duration of a timer
extension CTTVC {
    func replaceInTimer(_ referenceClock:Float, _ timerID:String?) {
        guard
            let bubbles = frc.fetchedObjects,
            let timer = bubbles.filter({ $0.id?.uuidString == timerID }).first,
            let indexPath = frc.indexPath(forObject: timer)
        else { return }
        
        endSession(timer)
        
        delayExecution(.now() + 0.1) { [weak self] in
            timer.referenceClock = referenceClock
            timer.currentClock = referenceClock
            CoreDataStack.shared.saveContext()
            
            let time = Int(referenceClock).time()
            let cell = self?.getCell(for: indexPath.row)
            cell?.hoursLabel.text = String(time.hr)
            cell?.minutesLabel.text = String(time.min)
            cell?.secondsButton.setTitle(String(time.sec), for: .normal)
            
            cell?.durationHoursLabel.text = String(time.hr)
            cell?.durationMinutesLabel.text = String(time.min)
            cell?.durationSecondsLabel.text = String(time.sec)
        }
    }
}

//Apparently, whenever leadingSwipeActionsConfigurationForRowAt is used, the cell is marked as being edited whenever it starts being swiped. And that allows us to use willBeginEditingRowAt and didEndEditingRowAt on the UITableView, without having to worry about the UITableViewCell
