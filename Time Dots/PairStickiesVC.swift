//
//  StickiesVC.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 19.03.2022.
//

import UIKit
import SwiftUI

class PairStickiesVC: UIViewController {
    func setupHostController() {
        let hostingController =
        UIHostingController(rootView: PairStickiesView(viewModel: PairStickyViewModel(pair: pair), stickyText: pair.sticky) {
            [weak self] in
            
            self?.dismiss(animated: true)
            self?.reloadStickies?()
        })
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        let frame = view.frame.concentric(x: .fractional(0.67), y: .fractional(0.52))
        hostingController.view.frame = frame
        hostingController.view.center = CGPoint(x: view.center.x + 10, y: view.center.y)
        hostingController.view.layer.cornerRadius = 30
        hostingController.view.addShadow()
    }
    
    // MARK: -
    var snapshot:UIView?
    weak var pair:Pair! {didSet{ setupHostController() }}
    var reloadStickies:(()->())?
    
    deinit {
        NotificationCenter.default.post(name: Post.animatePairCell, object: nil)
    }
}

extension PairStickiesVC {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let location = touches.first?.location(in: view),
            let touchedView = view.hitTest(location, with: nil)
        else { fatalError() }
        
        if touchedView.restorationIdentifier == "StickiesView" {
            dismiss(animated: false)
        }
    }
}
