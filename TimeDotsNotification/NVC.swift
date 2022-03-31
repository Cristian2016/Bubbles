import UIKit
import UserNotifications
import UserNotificationsUI
import WidgetKit

extension NVC {
    typealias ResponseOption = UNNotificationContentExtensionResponseOption
}

class NVC: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet var container: UIView!
    @IBOutlet var snoozeButtons: [UIButton]!
    
    @IBAction func restart(_ sender: UIButton) { }
    
    @IBAction func snooze5(_ sender: UIButton) { }
    
    @IBAction func snooze10(_ sender: UIButton) { }
    
    @IBAction func snooze15(_ sender: UIButton) { }
    
    @IBAction func snooze30(_ sender: UIButton) { }
    
    @IBAction func snooze1Hour(_ sender: UIButton) { }
    
    func didReceive(_ notification: UNNotification) {
        
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (ResponseOption) -> Void) {
        let content = response.notification.request.content
                
        let snoozes = ["5", "10", "15", "30", "60"]
        if let snooze = snoozes.filter({ $0 == response.actionIdentifier }).first {
            rescheduleNotification(with:content, at: TimeInterval(snooze)! * 60 /* seconds */)
            completion(.dismiss)
        }
        else { completion(.dismissAndForwardAction) }
    }
    
    // MARK: - helper
    private func rescheduleNotification(with content:UNNotificationContent, at timeInterval:TimeInterval) {
        let id = content.userInfo["timerIdentifier"] as? String ?? String.empty
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
