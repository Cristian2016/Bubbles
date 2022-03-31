//

//  Shake To Info.swift
//  Time Bubbles
//
//  Created by Cristian Lapusan on 21.04.2021.

import UIKit

extension UIViewController {
    
    private func addYellowInfoButtonInTheTopLeftCorner() {
        //make sure invisible button does not exist already. look for it in navigationController.subviews
        //or view.subviews and if found one return!
        var buttonFound = false
        if let nc = navigationController {//there is a navigation controller
            nc.view.subviews.forEach {
                if $0.restorationIdentifier == "invisibleButton" { buttonFound = true }
            }
        } else {//there is no navigation controller
            view.subviews.forEach {
                if $0.restorationIdentifier == "invisibleButton" { buttonFound = true }
            }
        }
        
        if buttonFound { return }
        
        //if invisible button does not exist already, make one!
        UserFeedback.triggerDoubleHaptic(.rigid)
        
        let origin = CGPoint(x: 0, y: ViewHelper.statusBarHeight() * 0.8)
        let invisibleButton =
            InvisibleButton(frame: CGRect(origin: origin, size: CGSize(width: 130, height: 130)))
        invisibleButton.backgroundColor = .clear
        invisibleButton.restorationIdentifier = "invisibleButton"
        invisibleButton.addTarget(self, action: #selector(yellowInfoButtonTapped(_:)), for: .touchUpInside)
    
        if let navigationController = navigationController {
            navigationController.view.addSubview(invisibleButton)
        }
        else {
            view.addSubview(invisibleButton)
        }
        
        //button transparent after 1 second, remove after 4 seconds
        delayExecution(.now() + 1.0) {
            invisibleButton.fillColor = invisibleButton.fillColor.withAlphaComponent(0.7)
        }
        delayExecution(.now() + 4) {
            invisibleButton.removeFromSuperview()
        }
    }
    
    @objc private func yellowInfoButtonTapped(_ sender:UIButton?) {
        if  UserDefaults.standard.value(forKey: UDKey.infoBannerNotShownAlready) == nil {
            UserDefaults.standard.setValue(true, forKey: UDKey.infoBannerNotShownAlready)
        }
        presentInfoVC()
        sender?.removeFromSuperview()
    }
    
    // MARK: - helper
    func prepare(_ infoVC:InfoVC) {
        var image = UIImage()
        
        let dark/* mode ON */ = infoVC.view.traitCollection.userInterfaceStyle == .dark
        switch restorationIdentifier {
        
        case "DetailVC": image = dark ? #imageLiteral(resourceName: "detailInfo") : #imageLiteral(resourceName: "detailInfo")
        case "ChronoTimersTVC": image = dark ? #imageLiteral(resourceName: "cttvcInfo") : #imageLiteral(resourceName: "cttvcInfo")
        case "PaletteVC": image = dark ? #imageLiteral(resourceName: "paletteInfo") : #imageLiteral(resourceName: "paletteInfo")
        case "TimerDurationVC": image = dark ? #imageLiteral(resourceName: "durationPickerInfo") : #imageLiteral(resourceName: "durationPickerInfo")
        case "moreOptionsVC": image = dark ? #imageLiteral(resourceName: "moreOptionsVCInfo") : #imageLiteral(resourceName: "moreOptionsVCInfo")
        case "EditDurationVC" : image = dark ? #imageLiteral(resourceName: "editDurationVCInfo") : #imageLiteral(resourceName: "editDurationVCInfo")
        case "DeleteActionVC": image = dark ? #imageLiteral(resourceName: "deleteActionVC") : #imageLiteral(resourceName: "deleteActionVC")
        case "StickiesVC": image = dark ? #imageLiteral(resourceName: "deleteActionVC") : #imageLiteral(resourceName: "deleteActionVC")
        default: break
        }
        
        let imageView = UIImageView(image: image)
        let ratio = infoVC.scrollView.bounds.width / image.size.width
        imageView.transform = CGAffineTransform(scaleX: ratio, y: ratio)
        imageView.frame.origin = .zero
        
        let contentWidth = imageView.bounds.size.width * ratio
        let contentHeight = imageView.bounds.size.height * ratio
        infoVC.scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        infoVC.scrollView.addSubview(imageView)
    }
    
    func presentInfoVC() {
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let infoVC = sb.instantiateViewController(identifier: "infoVC") as! InfoVC
        infoVC.modalPresentationStyle = .overCurrentContext
        infoVC.modalTransitionStyle = .crossDissolve
        
        delayExecution(.now() + 0.1) {
            [weak self] in
            self?.prepare(infoVC)
        }
        
        present(infoVC, animated: true, completion: nil)
    }
    
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard view.restorationIdentifier != "info" else {return}
        if presentingViewController?.restorationIdentifier != "infoVC" {
            if motion == .motionShake {
                //                navigationController?.viewControllers = []
                if presentingViewController?.restorationIdentifier != "DetailVC" {
                    addYellowInfoButtonInTheTopLeftCorner()
                }
            }
        }
    }
}

class InvisibleButton: UIButton {
    
    var fillColor = UIColor.yellow { didSet{ setNeedsDisplay() }}
    override func draw(_ rect: CGRect) {
        let roundedRect = rect.insetBy(dx: 4, dy: 4)
        let rectangle = UIBezierPath(roundedRect: roundedRect, cornerRadius: 14)
        fillColor.setFill()
        rectangle.fill()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        let infoSymbol = UIImageView(image: UIImage(systemName: "info.circle"))
        infoSymbol.isUserInteractionEnabled = false
        infoSymbol.translatesAutoresizingMaskIntoConstraints = false
        infoSymbol.alpha = 1.0
        addSubviewInTheCenter(infoSymbol)
        infoSymbol.pinOnAllSidesToSuperview(biggerBy: -20)
    }
}
