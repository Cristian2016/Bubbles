//
//  UserActivityName.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 11.06.2021.
//

import Foundation

extension CTTVC {
    enum UserActivityName:String {
        case start
        case pause
        case pauseAll
        case markEvent
        case markEventTitle
    }
    
    func createUserActivity(_ name:UserActivityName) {
        let title = "Pause All Time Bubbles" //for the user
        let id = UserActivityName.pauseAll.rawValue //for Siri
        let pauseAllActivity = NSUserActivity.activity(title, id)
        userActivity = pauseAllActivity
        pauseAllActivity.becomeCurrent() //this is the current activity
    }
}
