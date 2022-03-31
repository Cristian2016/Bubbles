//
//  Local Notifications.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 29.04.2021.
//

import UIKit


extension CTTVC {
    
    enum NotificationSituation {
        case endSession
        case start
        case pause
        case delete
    }
    
    ///before ct.state changed!!!
    internal func handleNotification(_ situation:NotificationSituation, for timer:CT) {
        guard timer.isTimer else { return }
        
        switch situation {
        case .pause: /* current situation is running */
            guard timer.state == .running else { return }
            notificationsManager.cancelScheduledNotification(for: timer)
        
        case /* now */.endSession: /* current situation is running */
            if timer.state == .running {/* for running timers only! the other ones */
                notificationsManager.cancelScheduledNotification(for: timer)
            }
            
        case /* now */ .start: /* current situation is paused */
            guard timer.state == .paused || timer.state == .brandNew else { return }
            notificationsManager.scheduleNotification(for: timer, atSecondsFromNow: TimeInterval(timer.currentClock), isSnooze: false)
            
        case .delete:
            if timer.state == .running {
                notificationsManager.cancelScheduledNotification(for: timer)
            }
        }
    }
    
    func snoozeNotification(_ timerIdentifier:String, _ snooze:TimeInterval) {
        let timer = frc.fetchedObjects?.filter { $0.id!.uuidString == timerIdentifier }.first
        if let timer = timer {
            notificationsManager.scheduleNotification(for: timer, atSecondsFromNow: snooze, isSnooze: true)
        }
    }
    
    ///user either touches notification to see ended timer or touch-holds on notification and selects "restart"
    func showTimerAndRestartIfAsked() {
        /*
         navigation controller receives notification from UserNotificationCenter: "user tapped notification". NC identifies the CT.id and sends it to CTTVC. CTTVC identifies the timer if it's still there and takes the user to that timer
         */
        guard
            let timerID = userTouchedNotification.timerID,
            let timers = frc.fetchedObjects?.filter({ $0.id?.uuidString == timerID }),
            let timer = timers.first,
            let indexPath = frc.indexPath(forObject: timer)
        else { return }
        
        
        //show timer
        scrollAndSelectBubble(at:indexPath)
        
        //repeat timer [is an option]
        if userTouchedNotification.restart != nil {
            //endSession and then start!
            let bubble = bubble(at: indexPath)
            endSession(bubble)
            delayExecution(.now() + 0.1) {[weak self] in
                /* again delay.. maybe it's the fucking recalibrateClock that needs time */
                self?.start(true, bubble)
                self?.getCell(for: indexPath.row)?.doneSticker.alpha = 0
            }
        }
    }
}

//// MARK: - Widgets and notifications
extension CTTVC {
    
    ///called when user taps a widget or notification
    func scrollAndSelectBubble(at indexPath: IndexPath) {
        //set this at the level of CTTVC, so that also scrollViewDidEndScrollingAnimation method has access to the value
        indexPathOfRowToBeSelected = indexPath
        
        //CTTVC not visible
        //1.Palette or DurationPicker visible
        //both of them are presented, NOT pushed on the stack just like regular children VCs of a navigation controller
        if navigationController?.topViewController !== self {
            /*
             ⚠️ wtf! If I don't use delayExecution, basically with no delay whatsoever, the timer will not display the correct duration. Normally it shows 0:0:0, but without delay it's crazy!
             */
            delayExecution(.now()) {[weak self] in
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        //2.either DetailVC, MoreOptionsVC or EditDurationVC visible
        if presentedViewController != nil {
            if presentedViewController?.restorationIdentifier == "EditDurationVC" {
                //⚠️ presentingVC is nil, but navigationController exists
                let cttvc = navigationController!.viewControllers.first as! CTTVC
                cttvc.prepareCellToExitEditMode()
            }
            
            dismiss(animated: true)
        }
        
        delayExecution(.now() + 0.5 /* ⚠️ sweet spot delay */) {[weak self] in
            //scroll and select
            self?.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            
            let cell = self?.tableView.cellForRow(at: indexPath)
            cell?.selectionStyle = .gray
            
            delayExecution(.now() + 0.4) {
                //select only if it was not selected
                if let isSelected = cell?.isSelected, !isSelected {
                    self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
                
                self?.indexPathOfRowToBeSelected = nil
            }
        }
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let indexPath = indexPathOfRowToBeSelected else { return }
        
        delayExecution(.now() + 0.4) {[weak self] in
            guard let self = self else { return }
            
            if let cell = self.tableView.cellForRow(at: indexPath), !cell.isSelected {
                let tableView = scrollView as? UITableView
                cell.selectionStyle = .gray //make sure selection color is gray
                if !cell.isSelected {
                    tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none) //◼︎
                    self.indexPathOfRowToBeSelected = nil //◼︎
                }
            }
        }
    }
}
