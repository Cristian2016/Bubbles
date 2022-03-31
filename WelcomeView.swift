//
//  WelcomeView.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 21.05.2021.
//

import UIKit

class WelcomeView: UIView {
    deinit {
//           print("WelcomeView deinit")
       }
    @IBOutlet weak var infoBanner: UIImageView! {didSet{
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideInfoBanner(_:)))
        addGestureRecognizer(tap)
        infoBanner.image = isDarkModeOn ? #imageLiteral(resourceName: "info inverted") : #imageLiteral(resourceName: "info")
    }}
    
    private let topImageViewAnimationDuration = 1.0
    private let bottomImageViewAnimationDuration = 2.0
    
    @IBOutlet weak var leftEdge: UIView!
    @IBOutlet var container: UIView!
    @IBOutlet weak var topImageView: UIImageView! {didSet{
        topImageView.image = isDarkModeOn ? #imageLiteral(resourceName: "start inverted") : #imageLiteral(resourceName: "start")
    }}
    @IBOutlet weak var greenArrow: UIImageView!
    @IBOutlet weak var bottomImageView: UIImageView! {didSet{
        bottomImageView.image = isDarkModeOn ?  #imageLiteral(resourceName: "Screenshot 2021-05-22 at 13.25.33") : #imageLiteral(resourceName: "Screenshot 2021-05-22 at 13.25.57")
    }}
    
    // MARK: - overrides
    override func willMove(toSuperview newSuperview: UIView?) {
        if UserDefaults.standard.value(forKey: UDKey.infoBannerNotShownAlready) == nil {
            showAllView(false)
        } else {
            infoBanner.alpha = 0
            startAnimations(delay: 2.0)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            let isDark = traitCollection.userInterfaceStyle == .dark
            topImageView.image = isDark ? #imageLiteral(resourceName: "start inverted") : #imageLiteral(resourceName: "start")
            bottomImageView.image = isDark ? #imageLiteral(resourceName: "Screenshot 2021-05-22 at 13.25.33") : #imageLiteral(resourceName: "Screenshot 2021-05-22 at 13.25.57")
            infoBanner.image = isDark ? #imageLiteral(resourceName: "info inverted") : #imageLiteral(resourceName: "info")
        }
    }
    
    // MARK: - init/deinit
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    private func setup() {
        
        let nibView = Bundle.main.loadNibNamed("WelcomeView", owner: self, options: nil)?.first as? UIView
        container = nibView
        container.frame = bounds
        addSubview(container)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        restorationIdentifier = "welcomeView"
    }
    
    private var animator:UIViewPropertyAnimator {
        
        let animator = UIViewPropertyAnimator(duration: 4.0, dampingRatio: 1.0)
        animator.addAnimations {
            [weak self] in
            self?.greenArrow.center.x += 200
        }
        animator.addAnimations({
            [weak self] in
            self?.greenArrow.alpha = 0
        }, delayFactor: 0.5)
        
        animator.addCompletion { [weak self] position in
            self?.greenArrow.transform = .identity
            self?.greenArrow.alpha = 1
            self?.greenArrow.center.x -= 200
        }
        
        return animator
    }
    
    // MARK: - Private
    var animationRepeatCount = 1
    private func startAnimations(delay:Double) {
        
        let timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] timer in
            
            delayExecution(.now() + delay) {
                [weak self] in
                guard let self = self else { return }
                
                if self.animationRepeatCount <= 0 { timer.invalidate() }
                self.animator.startAnimation()
                self.animationRepeatCount -= 1
            }
        }
        timer.fire()
    }
    
    @objc private func hideInfoBanner(_ sender:UITapGestureRecognizer) {
        infoBanner.alpha = 0
        
        showAllView(true)
        startAnimations(delay: 2.0)
    }
    
    private func showAllView(_ show:Bool) {
        leftEdge.alpha = show ? 1 : 0
        topImageView.alpha = show ? 1 : 0
        greenArrow.alpha = show ? 1 : 0
        bottomImageView.alpha = show ? 1 : 0
    }
}
