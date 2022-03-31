//
//  FetchedResultsControllerDelegate.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 30.01.2022.
//

import UIKit
import CoreData

// MARK: - changes in the model
extension CTTVC {
    
    func controller(_ controller: Controller, didChangeContentWith snapshot: SnapshotReference) {
        guard let bubbles = frc.fetchedObjects else {return}
        
        if bubbles.count == dds.snapshot().numberOfItems {// 1️⃣ drag-and-drop or property changes
            
            if userHasJustDraggedAndDroppedInTableView != nil {
                
                //snapshots
                //                makeAndApplySnapshot(fetchedResultsController.fetchedObjects ?? [], false)
                
                /* ------------------------------------------------------- */
                // TODO: test
                if let dragAndDropInfo = dragAndDropInfo {
                    var oldSnapshot = dds.snapshot() //old state
                    let item = dds.snapshot().itemIdentifiers[dragAndDropInfo.dropPosition]
                    if dragAndDropInfo.movedUp {
                        oldSnapshot.moveItem(bubbles.filter { $0.id == dragAndDropInfo.droppedItemID }.first!, beforeItem: item)
                    } else {
                        oldSnapshot.moveItem(bubbles.filter { $0.id == dragAndDropInfo.droppedItemID }.first!, afterItem: item)
                    }
                    
                    dds.apply(oldSnapshot, animatingDifferences: true)
                    
                } else { fatalError() }
                
                update_SecondsButtonTarget_ForEachVisibleCell(bubbles)
                update_HoursLabelDoubleTapTarget_ForEachVisibleCell(bubbles)
                /* ------------------------------------------------------- */
                
                //marbles
                bubbles.forEach { bubble in
                    if bubble.isTimer {
                        if bubble.state == .running { delayExecution(.now() + 0.05) {[weak self] in self?.syncMarble(of:bubble, for:.enterOnline) }}
                        else { self.syncMarble(of:bubble, for:.userPause) }
                    }
                }
                
                userHasJustDraggedAndDroppedInTableView = nil
            }
            
        } else {// 2️⃣ deletes or inserts
            guard
                snapshot.itemIdentifiers.count != dds.snapshot().numberOfItems,
                let bubbles = controller.fetchedObjects as? [CT]
            else { return }
            
            let insert = snapshot.itemIdentifiers.count > dds.snapshot().numberOfItems
            
            makeAndApplySnapshot(bubbles, insert ? false : true)
        }
        
        isTableViewEmpty = bubbles.isEmpty ? true : false
        
        shouldPresent_QuickStartGuide(bubbles.isEmpty)
    }
    
    //helpers
    fileprivate func makeAndApplySnapshot(_ bubbles: [CT], _ animation:Bool) {
        var snapshot = Snapshot()
        
        if snapshot.numberOfSections == 0 { snapshot.appendSections([.main]) }
        snapshot.appendItems(bubbles, toSection: .main)
        
        delayExecution(.now() + 0.01) {[weak self] in
            self?.dds.apply(snapshot, animatingDifferences: animation)
            
            /*
             ⚠️ mother fucking difficult to get it right
             visible cells are guaranteed to exist. the other ones may not exist yet,
             since this shit has a reuse identifier mechanism
             */
            self?.update_SecondsButtonTarget_ForEachVisibleCell(bubbles)
            
            //edit duration handler
            self?.update_HoursLabelDoubleTapTarget_ForEachVisibleCell(bubbles)
            
            //it's a stupid jump on iPhone Mini but not on iPhone 8 when a row gets inserted ⚠️
            if !animation {
                delayExecution(.now() + 0.2) {
                    self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            }
        }
    }
    
    private func update_SecondsButtonTarget_ForEachVisibleCell(_ bubbles:[CT]) {
        bubbles.forEach {
            if let indexPath = dds.indexPath(for: $0),
               let cell = tableView.cellForRow(at: indexPath) as? CTCell {
                
                cell.secondsButton.tag = indexPath.row
                cell.secondsButton.addTarget(self, action: #selector(self.secondsButtonTapped(button:)), for: .touchUpInside)
                (cell.secondsButton.gestureRecognizers?.first as? UILongPressGestureRecognizer)?.addTarget(self, action: #selector(self.secondsButtonPressed(gesture:)))
            }
        }
    }
    
    private func update_HoursLabelDoubleTapTarget_ForEachVisibleCell(_ bubbles:[CT]) {
        bubbles.forEach {
            if $0.isTimer {
                if let indexPath = dds.indexPath(for: $0),
                   let cell = tableView.cellForRow(at: indexPath) as? CTCell {
                    cell.doubleTap.addTarget(self, action: #selector(self.handleDoubleTap(_:)))
                }
            }
        }
    }
}

// MARK: - QuickStartGuide
extension CTTVC {
    private func shouldPresent_QuickStartGuide(_ noBubbles:Bool) {
        guard
            !UserDefaults.standard.bool(forKey: UDKey.quickStartGuidePresentedAlready),
            noBubbles else { return }
        
        presentTwoBubbles()
        delayExecution(.now() + 0.2) {
            //not implemented yet
            self.animateDestroyBubbles()
        }
    }
    
    private func presentTwoBubbles() {
        if let entityDescription = NSEntityDescription.entity(forEntityName: EntityName.ct, in: AppDelegate.context) {
            let timer = CT(entity: entityDescription, insertInto: AppDelegate.context)
            timer.populate(color: "Sour Cherry", kind: .timer(limit: 30))
        }
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: EntityName.ct, in: AppDelegate.context) {
            let stopWatch = CT(entity: entityDescription, insertInto: AppDelegate.context)
            stopWatch.populate(color: "Byzantium", kind: .stopwatch)
        }
        
        UserDefaults.standard.set(true, forKey: UDKey.quickStartGuidePresentedAlready)
        
        CoreDataStack.shared.saveContext()
    }
    
    private func animateDestroyBubbles() {
        // TODO: implement
    }
}
