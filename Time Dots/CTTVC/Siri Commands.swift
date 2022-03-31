//
//  Siri Commands.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 07.01.2022.
//

import UIKit

// MARK: - Compatibility with Siri Commands
extension CTTVC {
    ///start or pause a bubble [timer or stopwatch]
    func startPause(_ bubble:CT) {
        let cell = tableView.cellForRow(at: frc.indexPath(forObject: bubble)!) as! CTCell
        
        if bubble.state == .zeroTimer {
            hintViewManager.toggleHint(for:.resetTimer, in:cell)
            return
        }
        
        //"undo save" feature
        if !undoSave_IndexPathDate_Tuples.isEmpty {
            cell.showUndoSaveHint(false)
            for (index, tuple) in undoSave_IndexPathDate_Tuples.enumerated() {
                if tuple.indexPath == tableView.indexPath(for: cell) {
                    undoSave_IndexPathDate_Tuples.remove(at: index)
                }
            }
        }
        
        /* ⚠️ change state first! then the code that follows handles the new state */
        switch bubble.state {
        case .zeroTimer: break
            
        case .brandNew,.paused:
            //⚠️ before start otherwise it will not show brand new
            saveTimerDuration(for: bubble)
            
            start(true, bubble) /* start */
            storeInSharedFolder(bubble)
            
        case .running:
            start(false, bubble) /* pause */
        }
    }
}
