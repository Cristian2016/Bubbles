//
//  Coordinator.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Thu  25.02.2021.
//

import Foundation
import UserNotifications
import UIKit
import CoreData

extension  ScheduledNotificationsManager {
    typealias Action = UNNotificationAction
    typealias Content = UNMutableNotificationContent
    typealias Category = UNNotificationCategory
}

class ScheduledNotificationsManager {
    struct CategoryName {
        static let zeroTimer = "zeroTimer" //timer has ended
        static let runningTimer = "runningTimer"
        static let snooze = "snooze"
    }
    struct ActionID {
        static let repeatTimer = "repeat timer"
        static let snoozeTimer = "snooze timer" //not used
        static let pauseTimer = "pauseTimer" //not used yet
        static let resumeTimer = "resumeTimer" //not used yet
    }
    
    // MARK: -
    private lazy var center = UNUserNotificationCenter.current()
    
    // MARK: - Public
    
    static let shared = ScheduledNotificationsManager()
    private init() { }
    
    //asks user for permission to post notifications
    func requestAuthorization() {
        center.requestAuthorization(options: options) {
            completed, error in
        }
    }
    private lazy var options:UNAuthorizationOptions = [
        .alert,
        .sound,
        .badge,
        .carPlay,
        .announcement,
//        .providesAppNotificationSettings,
//        .provisional
    ]
    
    ///ex: user starts 10 minutes timer. a notification is scheduled to for delivery at 10 minutes after timer start
    func scheduleNotification(for timer:CT, atSecondsFromNow timeInterval:TimeInterval, isSnooze:Bool) {
        /* this method called from snooze also, not only when timer started or paused. snooze is a particular case since currentClock for snooze is zero. so I added the isSnooze parameter */
        
        guard
            let color = timer.color,
            let timerIdentifier = timer.id?.uuidString, timer.isTimer
        else { return }
        
        if !isSnooze && timer.currentClock <= 0 { return }
                
        let duration = timer.referenceClock
        
        //1.notification content
        let content = Content()
        let sound = UNNotificationSound(named: UNNotificationSoundName("magic.mp3"))
        content.sound = sound
        content.userInfo = ["duration": Int(duration),
                            "sticky":timer.stickyNote,
                            "color":color,
                            "timerIdentifier":timerIdentifier,
                            "date":Date(),
                            "triggerTimeInterval":timeInterval]
        
        content.categoryIdentifier = CategoryName.zeroTimer /* ⚠️  */
        content.title = contentTitle(timer)
        content.body = "Duration \(Int(duration).timeAsString())"
        
        if let image = image(for: color) { content.attachments = [image] }
        
        //2.trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        //request with 1 and 2
        let request = UNNotificationRequest(identifier: timerIdentifier, content: content, trigger: trigger)
        
        //actions
        var actions = [ScheduledNotificationsManager.Action]()
        
        let snoozeActions = snoozeActions()
        actions.append(repeatAction)
        actions.append(contentsOf: snoozeActions)
        
        //category with actions
        let zeroTimerCategory = Category(identifier: CategoryName.zeroTimer,
                                 actions: actions,
                                 intentIdentifiers: [], /* for Siri.. */
                                 options: [])
        
        //category and request
        center.setNotificationCategories([zeroTimerCategory])
        center.add(request)
    }
    
    ///ex: user pauses the timer. no reason to notify for a paused timer, so the scheduled notification will be removed
    func cancelScheduledNotification(for timer:CT) {
        guard let identifier = timer.id?.uuidString else {fatalError()}
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    func removeDeliveredAndPendingNotifications(for timer:CT) {
        
        guard
            let identifier = timer.id?.uuidString,
            timer.isTimer
        else { return }
        
        //remove 1.delivered and 2.'not yet delivered' notifications
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    ///called the moment the user has set a running timeBubble's sticky note
    func updateStickyNoteInNotification(for timer:CT) {
        guard
            timer.isTimer, timer.state == .running,
            let identifier = timer.id?.uuidString
        else { return }
        
        let momentOfStickyNoteSet = Date()
        
        center.getPendingNotificationRequests { [weak self] requests in
            guard
                let self = self,
                let request = requests.filter({ $0.identifier == identifier }).first
            else { return }
            
            //use request.content properties to populate an empty content
            let content = UNMutableNotificationContent()
            content.sound = request.content.sound
            content.userInfo = request.content.userInfo
            content.categoryIdentifier  = request.content.categoryIdentifier
            content.body = request.content.body
            content.attachments = request.content.attachments
            content.title = self.contentTitle(timer)
            content.categoryIdentifier = request.content.categoryIdentifier
            let requestID = content.userInfo["timerIdentifier"] as! String
            
            let initialTimeInterval = request.content.userInfo["triggerTimeInterval"] as! TimeInterval
            let adjustedTimeInterval = initialTimeInterval - momentOfStickyNoteSet.timeIntervalSince(request.content.userInfo["date"] as! Date)
            let adjustedTrigger = UNTimeIntervalNotificationTrigger(timeInterval: adjustedTimeInterval, repeats: false)
            let newRequest = UNNotificationRequest(identifier: requestID, content: content, trigger: adjustedTrigger)
            
            UNUserNotificationCenter.current().add(newRequest)
        }
    }
    
    func updateTimerColorInNotification(for timer:CT) {
        guard
            timer.isTimer, timer.state == .running,
            let identifier = timer.id?.uuidString
        else { return }
        
        let momentOfStickyNoteSet = Date()
        
        center.getPendingNotificationRequests { [weak self] requests in
            guard
                let self = self,
                let request = requests.filter({ $0.identifier == identifier }).first
            else { return }
            
            //use request.content properties to populate an empty content
            let content = UNMutableNotificationContent()
            content.sound = request.content.sound
            content.userInfo = request.content.userInfo
            content.categoryIdentifier  = request.content.categoryIdentifier
            content.body = request.content.body
            
            //this will be updated. all the rest of the code is identical to updateStickyNoteInNotification
            if let image = self.image(for: timer.color) { content.attachments = [image] }
            
            content.title = self.contentTitle(timer)
            content.categoryIdentifier = request.content.categoryIdentifier
            let requestID = content.userInfo["timerIdentifier"] as! String
            
            let initialTimeInterval = request.content.userInfo["triggerTimeInterval"] as! TimeInterval
            let adjustedTimeInterval = initialTimeInterval - momentOfStickyNoteSet.timeIntervalSince(request.content.userInfo["date"] as! Date)
            let adjustedTrigger = UNTimeIntervalNotificationTrigger(timeInterval: adjustedTimeInterval, repeats: false)
            let newRequest = UNNotificationRequest(identifier: requestID, content: content, trigger: adjustedTrigger)
            
            UNUserNotificationCenter.current().add(newRequest)
        }
    }
    
    // MARK: - Organize
    
    
    // MARK: - Actions
    //actions of Category "zeroTimer"
    private lazy var repeatAction:Action = {
        
        let id = ActionID.repeatTimer
        let title = "Repeat Timer"
        return Action(identifier: id, title: title, options: [.foreground, .destructive])
    }()
    private func snoozeActions() -> [Action] {
        
        let snoozes = [5, 10, 15, 30, 60/* minutes */]
        
        var actions = [Action]()
        
        snoozes.forEach {
            //set action title
            let title:String
            if $0 != 60 { title = "Snooze \($0)".appending(($0 == 5) ? " Minutes" : String.empty) }
            else { title = "Snooze 1 Hour" }
            
            let snoozeAction = Action(identifier: "\($0)", title: title, options: [])
            actions.append(snoozeAction)
        }
        
        return actions
    }
    
    //actions of Category "runningTimer"
    // TODO: add here start and pause actions from the lockscreen and show running clock
    private func pause_Action() -> Action {
        Action(identifier: ActionID.pauseTimer, title: "Pause Timer", options: [])
    }
    private func resume_Action() -> Action {
        Action(identifier: ActionID.resumeTimer, title: "Resume Timer", options: [])
    }
    
    // MARK: - Helpers
    //attachment images
    private func image(for color:String?) -> UNNotificationAttachment? {
        guard let url = Bundle.main.url(forResource: color, withExtension: "png") else { fatalError() }
        guard let color = color else { return nil }
        
        return try? UNNotificationAttachment(identifier:color, url:url, options:nil)
    }
    
    private func contentTitle(_ timer:CT) -> String {
        let timerDone = "Done!"
        if !timer.stickyNote.isEmpty {
            return timer.stickyNote + " " + timerDone
        }
        return timer.color! + " • " + timerDone
    }
}
