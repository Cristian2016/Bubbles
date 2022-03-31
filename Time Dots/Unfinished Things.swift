//
//  Testing.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Fri  9.04.2021.
//

import UIKit

protocol KeyboardSafe:AnyObject {
    associatedtype CellItem: UITableViewCell //any tableview or collectionview cell
    var cell:CellItem { get }
    var cellBoundsInCoordinateSpace:CGRect? {get set}
}

extension KeyboardSafe {
    func registerFor_TexfieldDidBeginEditing() {
        let nc = NotificationCenter.default
        let post = NSNotification.Name("textFieldDidBeginEditing")
        
        nc.addObserver(forName: post, object: nil, queue: nil) {
            [weak self] notification in
            guard
                let self = self,
                let cell = ((notification.object as? StickyNote)?.superview?.superview as? PairCell)
            else { return }
            
            /* ⚠️ bounds not frame */
            self.cellBoundsInCoordinateSpace = cell.convert(cell.bounds /* ⚠️ */, to: nil)
        }
    }
    
    func registerFor_KeyboardFrame_Updates() {
        let nc = NotificationCenter.default
        let willChangeFrame = UIResponder.keyboardWillChangeFrameNotification
        nc.addObserver(forName: willChangeFrame, object: nil, queue: nil) {
            [weak self] notification in
            guard let self = self else { return }
            
            let key = UIResponder.keyboardFrameEndUserInfoKey
            guard let keyboardFrame = (notification.userInfo![key] as? CGRect) else {return}
            
            if keyboardFrame.origin.y < UIScreen.main.bounds.height {
                guard let cellBounds = self.cellBoundsInCoordinateSpace else { return }
                
                let obscureAmount = (cellBounds.origin.y + cellBounds.size.height) - keyboardFrame.origin.y
                if obscureAmount > 0 {
                    self.cell.transform = CGAffineTransform(translationX: 0, y: -obscureAmount)
                }
            }
            else { self.cell.transform = .identity }
        }
    }
}

