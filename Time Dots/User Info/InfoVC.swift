//
//  InfoVC.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 21.04.2021.
//

import UIKit
import SwiftUI

class InfoVC: UIViewController {
    @IBOutlet weak var gesturesImage: UIImageView!
    
    @IBOutlet weak var userInfoBackground: UserInfoBackground! {didSet{
        userInfoBackground.layer.shadowOffset = CGSize(width: 1, height: 1)
        userInfoBackground.layer.shadowOpacity = 0.5
        
        let shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0.6).cgColor
        userInfoBackground.layer.shadowColor = shadowColor
    }}
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func toggleAnimations(_ sender: AnimationsButton) {
        
        let key = UserDefaults.Key.isAnimationOnAppearEnabled
        if let isAnimationEnabled = UserDefaults.standard.value(forKey: key) as? Bool {
            
            UserDefaults.standard.setValue(!isAnimationEnabled, forKey: key)
            sender.setup()
            UserFeedback.triggerSingleHaptic(.light)
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) { sender.transform = .identity }
            }
            
        } else {/*
             value not set yet. set it here to true!
             */
            
            UserDefaults.standard.setValue(true, forKey: key)
            sender.strokeColor = .red
            sender.setTitle("On", for: .normal)
            sender.setTitleColor(.green, for: .normal)
        }
    }
    
    @objc private func dismissSelf(_ sender:UITapGestureRecognizer) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground.withAlphaComponent(0.85) //darkmode
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf(_:)))
        view.addGestureRecognizer(tap)
        
       adaptUI()
    }
}

extension InfoVC {
    //ex: called when the user toggles darkmode in control center
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            adaptUI()
        }
    }
    
    private func adaptUI() {
        gesturesImage.image = view.isDarkModeOn ? UIImage(imageLiteralResourceName: "gestures") : UIImage(imageLiteralResourceName: "gestures")
    }
}
