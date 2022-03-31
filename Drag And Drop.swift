//
//  DragDelegate.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Mon  22.03.2021.

// code in 2 places: cttvc.viedidload and here
// override func viewDidLoad() {
//tableView.dragInteractionEnabled = true /* local drag */
//tableView.dragDelegate = self
//tableView.dropDelegate = self

import UIKit
import CoreData

// MARK: - dragging and dropping
extension CTTVC : UITableViewDragDelegate, UITableViewDropDelegate {
    
    // MARK: Drag phase
    /* phase 1. user touches minutesLabel of a cell */
    func tableView(_ tableView: TV, itemsForBeginning session: UIDragSession, at indexPath: IP) -> [UIDragItem] {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? CTCell else { return [] }
        
        let ct = frc.object(at:indexPath)
        
        //represents the model object
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        
        //associate the ct with the drag object
        dragItem.localObject = ct
        
        //make sure user touches the minutes label. hitTest method returns the stackView but that's ok. at least for now
        let fingerIsOnMinutesLabel = userTouchedMinutesLabel(for: cell, and: session)
       
        return fingerIsOnMinutesLabel ? [dragItem] : []
    }
    
    private func userTouchedMinutesLabel (for cell:CTCell, and session:UIDragSession) -> Bool {
        
        let fingerLocationInsideCell = session.location(in: cell)
        let hitTestView = cell.hitTest(fingerLocationInsideCell, with: nil)
        guard let itsTheMinutelLabel = hitTestView?.isKind(of: UIStackView.self) else { return false }
        
        return itsTheMinutelLabel
    }
    
    func tableView(_ tableView: TV, canHandle session: Drop) -> Bool {
        session.localDragSession != nil
    }
    
    // MARK: Drop phase
    func tableView(_ tableView: TV, dropSessionDidUpdate session: Drop, withDestinationIndexPath destinationIndexPath: IP?) -> DropProposal {
        
        let proposal:DropProposal
        
        guard tableView.hasActiveDrag else {
            return DropProposal(operation: .cancel)
        }
        
        proposal = DropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        return proposal
    }
    
    
    func tableView(_ tableView: TableView, performDropWith coordinator: DropCoordinator) {
        guard
            let hoveringBubble = coordinator.session.items.first?.localObject as? CT,
            let source = frc.indexPath(forObject: hoveringBubble),
            
                let destination = coordinator.destinationIndexPath,
            
                let bubblesCount = frc.fetchedObjects?.count,
            destination != source,
            destination.row >= 0, destination.row <= bubblesCount - 1,
            let bubbles = frc.fetchedObjects
        else { return }
        
        var indices = [Int]()
        for (index, _) in bubbles.enumerated() { indices.append(index) }
        let removedIndex = indices.remove(at: source.row)
        indices.insert(removedIndex, at: destination.row)
        
        var value = 0
        indices.reversed().forEach { index in
            bubbles[index].rank = -Int32(value)
            value -= 1
        }
        
        userHasJustDraggedAndDroppedInTableView = true
        if let userHasJustDraggedAndDroppedInTableView = userHasJustDraggedAndDroppedInTableView, userHasJustDraggedAndDroppedInTableView {
            let movedUp = source.row - destination.row > 0
            let dropPosition = destination.row
            let droppedItemID = hoveringBubble.id
            dragAndDropInfo = DragAndDropInfo(movedUp: movedUp, dropPosition: dropPosition, droppedItemID: droppedItemID)
        }
        CoreDataStack.shared.saveContext()
    }
    
    struct DragAndDropInfo {
        let movedUp:Bool
        let dropPosition:Int
        let droppedItemID:UUID?
    }
}
