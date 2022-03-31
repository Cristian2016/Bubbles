import UIKit

class ColorCircle: UIButton {
    // MARK: - PRIVATE 🚫
    // MARK: properties
    private var scaleAnimator:PropertyAnimator?
    
    // MARK: methods
    /// sets Circle.fillColor property. method called within both initializers
    private func setColor() {
        /* Circle.currentTitle must match tricolor.name */
        guard
            let matchingTricolor = TricolorProvider.tricolors.filter({$0.name == currentTitle}).first
            else {return}
        color = matchingTricolor.intense
    }
    private func setupInit() {/*
        1. set animator
        2. set fillColor for each circle
        3. exclusive touch meaning no other view will process touch events*/
        setColor()
        isExclusiveTouch = true /*
        blocks delivery of touch events to other views in the same window*/
    }
    private func prepareForDeinit() {
        scaleAnimator?.pausesOnCompletion = false /*⚠️
         why if this property only deinits if it's false?*/
    }
    private func setScaleAnimator() {
        scaleAnimator = PropertyAnimator(duration: 0.35, dampingRatio: 0.3, animations: {
            [weak self] in
            self?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        })
        
        scaleAnimator?.pausesOnCompletion = true
    }
    
    // MARK: - PUBLIC
    // MARK: properties
    private(set) var color = UIColor()
    
    // MARK: - overrides
    override func draw(_ rect: CGRect) {
        /*draw(.) called only once when Palette initialized*/
        let path = UIBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
    }

    // MARK: - init/ deinit
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupInit()
    }
    
    deinit {
        prepareForDeinit()
    }
    
    private func displayUserInfoAlertInUserInfoView(isDisplayed:Bool) {
//        if let paletteUserInfoView = ((paletteView?.window?.rootViewController as? UINavigationController)?.topViewController as? Palette)?.userInfoView {
//            if isDisplayed {
//                if paletteUserInfoView.subviews.count == 1 {paletteUserInfoView.subviews.last?.removeFromSuperview()}
//                UserInfo.displayLabel(inSuperview: paletteUserInfoView, forReason: .releaseCircleToCreateNewTimer, infoType: .alert)
//            } else {
//                paletteUserInfoView.subviews.last?.removeFromSuperview()
//                UserInfo.displayLabel(inSuperview: paletteUserInfoView, forReason: .explainingHowPaletteWorks, infoType: .normal)
//            }
//        }
    }
}

// MARK: - mostly animator
extension ColorCircle {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        /*each time a circle is touched
         it is brought in front of other circles, so that it is not obscured by the others*/
        if superview?.superview?.subviews.last != superview || superview?.subviews.last != self {
            superview?.superview?.bringSubviewToFront(superview!)
            superview?.bringSubviewToFront(self)
        }
        
        codeFor(.touchesBegan, scaleAnimator)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        codeFor(.touchesEnded, scaleAnimator)
        displayUserInfoAlertInUserInfoView(isDisplayed: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        codeFor(.touchesCancelled, scaleAnimator)
        displayUserInfoAlertInUserInfoView(isDisplayed: false)
    }
    
    /*easier to deal in one method with touchesBegan Ended Cancelled code*/
    private enum MethodName {
        case touchesBegan
        case touchesEnded
        case touchesCancelled
    }
    private func codeFor(_ methodName:MethodName, _ animator:PropertyAnimator?) {
        guard let scaleAnimator = scaleAnimator else {return}
        
        switch methodName {
        case .touchesBegan:
            if scaleAnimator.state == .active {
                if scaleAnimator.isRunning {scaleAnimator.pauseAnimation()}
                scaleAnimator.isReversed = false
            }
            scaleAnimator.startAnimation()
        
        case .touchesEnded:
            scaleAnimator.pauseAnimation()
            scaleAnimator.isReversed = true
            scaleAnimator.startAnimation()
            
        case .touchesCancelled:break
            // TODO: finish
        }
    }
    
    /*animator set here each time Palette goes onscreen (including when circle initialized)*/
    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {/*PaletteVC will move offscreen*/
            if scaleAnimator?.state == .active {
                scaleAnimator?.stopAnimation(false)
                scaleAnimator?.finishAnimation(at: .start)
            }
            scaleAnimator = nil
        } else {/*PalletteVC move onscreen*/
            setScaleAnimator()
        }
    }
}

class PropertyAnimator: UIViewPropertyAnimator { }
