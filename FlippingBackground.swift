//
//  TableBackgroundProtocol.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 26.01.2022.
//

import UIKit

protocol FlippingBackground : AnyObject {
    //have default implementations
    var container:UIView! { get }
    var backgroundScaleUpValue:CGFloat { get }
    func positionContainer()
    
    //have NO default implementations
    var cellFrame:CGRect! { get }
    var background:TableBackground! { get set }
    var isContainerBelowEditedCell:Bool! { get set }
    var view:UIView! { get } //VC.view
    var containerCenterYAnchor: NSLayoutConstraint! { get set }
    func setupContainer_FlipGestures()
}

//default implementations
extension FlippingBackground {
    var container:UIView! { background }
    
    var backgroundScaleUpValue:CGFloat { 1.0 }
    
    func positionContainer() {
        let cellBottomEdgeY = cellFrame.origin.y + cellFrame.height
        let cellTopEdgeY = cellFrame.origin.y
        
        let containerFrame = container.absoluteFrame()
        let containerCenter = container.absoluteCenter()
        
        isContainerBelowEditedCell = background.frame.height * backgroundScaleUpValue <= (view.frame.height - cellBottomEdgeY)
        
        //wantedCenter
        let wantedCenterY = isContainerBelowEditedCell ?
        cellBottomEdgeY + containerFrame.height/2  :
        cellTopEdgeY - containerFrame.height/2
        
        let delta = abs(containerCenter.y - wantedCenterY)
        let translationY = (containerCenter.y <= wantedCenterY) ? delta : -delta
        
        //update fucking anchor
        containerCenterYAnchor.constant += translationY
        view.layoutIfNeeded()
    }
}
