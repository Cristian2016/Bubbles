//
//  Notification Delegate.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 28.04.2021.
//

import UIKit

extension NavigationController {
    typealias Response = UNNotificationResponse
    typealias Center = UNUserNotificationCenter
    typealias Notification = UNNotification
    typealias PresentationOptions = UNNotificationPresentationOptions
}

//to display notifications in app you need this!
/*
 the delegate is set in the viewdidload: self.viewDidLoad { UNUserNotificationCenter.current().delegate = self }
 */
extension NavigationController:UNUserNotificationCenterDelegate {

    // MARK: - delegate methods
    func userNotificationCenter(_ center: Center,
                                willPresent notification: Notification,
                                withCompletionHandler completionHandler: @escaping (PresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .banner, .list])
    }

    func userNotificationCenter(_ center: Center,
                                didReceive response: Response,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        /*
         here I decide how to handle user intents
         ex:
         1.if user taps notification -> UNNotificationDefaultActionIdentifier case
         2.user wants to repeat timer it's "repeat timer" action
         */
        
        let timerID = self.getTimerID(from: response) //which timer was it
        guard let cttvc = self.viewControllers.first as? CTTVC
        else { return }
        
        switch response.actionIdentifier {
            
        case UNNotificationDefaultActionIdentifier:
            /*
             user taps notification
             if app was killed, it needs time to restart. without delay app crashes
             */
            delayExecution(.now() + 0.1) {
                cttvc.userTouchedNotification = (timerID, nil)
            }
            
        case "repeat timer": //takes user to the finished timer and restarts it
            delayExecution(.now() + 0.1) {
                cttvc.userTouchedNotification = (timerID, true)
            }
            
        default:
            //snoozes are normally handled by the extension! if God forbid! Ptui ptui ptui! :))), extension crashes, then this piece of code handles it instead!
            let snoozes = [5, 10, 15, 30, 60]
            snoozes.forEach {
                if response.actionIdentifier == String($0) {
                    cttvc.snoozeNotification(timerID, TimeInterval($0) * 60 /* seconds */)
                }
            }
        }
        
        completionHandler()
    }

    // MARK: helpers
    //maybe app is dead, so try to use a notification to the CTTVC instead. see if it works. if not, fuck it!
    private func notifyCTTVCToRestartTimer(for timerID:String) {

        let name = NSNotification.Name(rawValue: "repeatTimerWhenYouWakeUp")
        let info = ["timerID" : timerID]
        delayExecution(.now() + 0.1) {
            NotificationCenter.default.post(name: name, object: nil, userInfo: info)
        }
    }

    private func getTimerID(from response:Response) -> String {
        response.notification.request.identifier
    }
}
