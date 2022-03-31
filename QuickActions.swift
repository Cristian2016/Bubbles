//
//  QuickActions.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 27.05.2021.
//

import UIKit

class QuickAction {
    let icon = UIApplicationShortcutIcon(systemImageName: "calendar.badge.plus")
    lazy var markInCalendar:UIMutableApplicationShortcutItem = {
        let item = UIMutableApplicationShortcutItem(type: "id1",
                                                    localizedTitle: "Mark in Calendar",
                                                    localizedSubtitle: nil,
                                                    icon: icon,
                                                    userInfo: nil)
        return item
    }()
    func addToShortcutItems() {
        if let isEmpty = UIApplication.shared.shortcutItems?.isEmpty, isEmpty {
            UIApplication.shared.shortcutItems?.append(markInCalendar)
        }
    }
}
