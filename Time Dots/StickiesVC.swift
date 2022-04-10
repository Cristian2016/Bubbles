//
//  StickiesVC.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 19.03.2022.
//

import UIKit
import SwiftUI

extension StickiesVC {
    typealias HC = UIHostingController
}

class StickiesVC: UIViewController {
    func setupHostController() {
        //hosting controller
        let hc = HC(rootView: PairStickiesView(.init(pair)) { [weak self] in
            
            self?.dismiss(animated: true)
            self?.reloadStickies?()
        })
        
        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)
        
        let frame = view.frame.concentric(x: .fractional(0.67), y: .fractional(0.52))
        hc.view.frame = frame
        hc.view.center = CGPoint(x: view.center.x + 10, y: view.center.y)
        hc.view.layer.cornerRadius = 30
        hc.view.addShadow()
    }
    
    // MARK: -
    weak var pair:Pair! {didSet{ setupHostController() }}
    var reloadStickies:(()->())?
    
    deinit {
        NotificationCenter.default.post(name: Post.animatePairCell, object: nil)
    }
}

extension StickiesVC {
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
