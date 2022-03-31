//
//  SceneDelegate.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Tue  23.02.2021.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    static var didEnterBackgroundAt:Date?
    static let statusBarManager = UIApplication.shared.windows.first?.windowScene?.statusBarManager
    
    var window: UIWindow?
    private func cttvc() -> CTTVC? {
        (window?.rootViewController as? NC)?.viewControllers.first as? CTTVC
    }
    
    // MARK: - online offline
    func sceneWillEnterForeground(_ scene: UIScene) {
        delayExecution(.now() + 0.1) {
            //delay so that CTTVC.fetchedResultsController is set
            [weak self] in
            self?.cttvc()?.prepareCTsForOnline()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        //fetchedResultsController is nil if you dont add some delay
        delayExecution(.now() + 0.1) { [weak self] in
            self?.cttvc()?.frc?.fetchedObjects?.forEach {
                self?.cttvc()?.shouldEndCurrentSession(for: $0)
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        UserDefaults.standard.saveDate(Date(), key: .appDidEnterBackground)
    }
    
    // MARK: -
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        switch shortcutItem.localizedTitle {
        case "Mark in Calendar":
            CalendarEventsManager.shared.newQuickActionEvent()
        default: break
        }
    }
    
    //Widget: handle deep links coming from widgets
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            if let host = components?.host { cttvc()?.handleURLHost(host) }
        }
    }
}

//extension SceneDelegate {
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        print(#function)
//    }
//
//    func sceneDidDisconnect(_ scene: UIScene) {
//        print(#function)
//    }
//}
