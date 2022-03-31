//
//  FileManager Extension.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 16.06.2021.
//

import Foundation

extension FileManager {
    //these should not change
    static let groupIdentifier = "group.com.TimeBubbles.widget"
    
    static let sharedFolder:URL = {
        guard let sharedFolder =
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FileManager.groupIdentifier)
        else { fatalError() }
        return sharedFolder
    }()
    
    //changes all the time
    ///files where time bubble data is stored for the widget and Siri Intents
    static var sharedFiles:[URL] {
        let fileManager = FileManager.default
        guard
            let contents = try? fileManager.contentsOfDirectory(at: sharedFolder,
                                                                includingPropertiesForKeys: nil,
                                                                options: [])
        else {fatalError()}
        
        return contents.filter { $0.path.contains("json") }
    }
    
//    static let widgetEnabledTimeBubbleListFile:URL = FileManager.sharedFolder.appendingPathComponent("widgetEnabledTimeBubbleList")
    
    static let sharedDatabase:URL = {
        FileManager.sharedFolder.appendingPathComponent("sharedDatabase.sqlite")
    }()
    
    // MARK: - Test
    static func testSharedFolder() {
        let file = FileManager.sharedFolder.appendingPathComponent("random")
        try? String(Int.random(in: 0...10_000_000)).write(to: file, atomically: true, encoding: .utf8)
    }
}

extension DateComponents {
    func minus() -> DateComponents {
        DateComponents(hour: -(hour ?? 0), minute: -(minute ?? 0), second: -(second ?? 0))
    }
}
