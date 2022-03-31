/*https://youtu.be/xu9oeCAS8aA?t=683*/

import UIKit

public extension CABasicAnimation {
    static func fadeOut(duration:Double) -> CABasicAnimation {
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.duration = CFTimeInterval(duration)
        animation.fromValue = 1.0
        animation.toValue = 0.0
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
}

//5 animations used in Time Bubbles
public extension CAKeyframeAnimation {
    typealias KFAnimation = CAKeyframeAnimation
    
    //1
    static func pendulumSwingAroundCenter(duration:Double) -> KFAnimation {
        let animation = KFAnimation(keyPath: "transform.rotation.z")
        
        animation.duration = CFTimeInterval(duration)
        animation.values = [0,
                            -CGFloat.pi/40, CGFloat.pi/30,
                            -CGFloat.pi/60, CGFloat.pi/50,
                            -CGFloat.pi/80, CGFloat.pi/70, 0]
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
    
    //2
    static func scaleUpAndDown(duration:Double, scaleValues:[Double]) -> KFAnimation {
        let animation = KFAnimation(keyPath: "transform.scale")
        
        animation.duration = CFTimeInterval(duration)
        animation.values = scaleValues
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
    
    //3
    static func horizontalWobble(duration:Double) -> KFAnimation {
        let animation = KFAnimation(keyPath: "position.x")
        animation.duration = CFTimeInterval(duration)
        animation.values = [0, 100, -100, 90, -90, 80, -80, 70, -70, 60, -60, 50, -50, 40, -40, 30, -30, 20, -20, 10, -10, 0]
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
    
    //4
    static func alpha(color:UIColor, duration:Double) -> KFAnimation {
        
        let animation = KFAnimation(keyPath: "backgroundColor")
        animation.duration = CFTimeInterval(duration)
        animation.values = [UIColor.clear.cgColor, color]
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
    
    //5
    static func translationX(duration:Double, translationValues:[Double]) -> KFAnimation {
        let animation = KFAnimation(keyPath: "position.x")
        animation.duration = CFTimeInterval(duration)
        animation.values = translationValues
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        animation.isAdditive = true
        return animation
    }
    
    //6
    static func translationY(duration:Double, translationValues:[Double], repeatCount:Float) -> KFAnimation {
        let animation = KFAnimation(keyPath: "position.y")
        animation.duration = CFTimeInterval(duration)
        animation.values = translationValues
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        
        animation.isAdditive = true
        return animation
    }
}

public extension UIView {
    
    var isVisible:Bool {
        alpha == 1 ? true : false
    }
    
    ///the middle of the view's frame
    var middle:CGPoint {
        CGPoint(x: frame.width/2 , y: frame.height/2)
    }
    
    func pinViewToTheBottomOf(_ superview:UIView) {
        guard window != nil else {
            fatalError("window not visible yet")
        }
        
        let screenHeight = UIScreen.main.bounds.height
        let viewHeight = frame.height
        
        frame.origin = CGPoint(x: UIScreen.main.bounds.midX - frame.midX, y: screenHeight - viewHeight)
    }
    
    func removeRestorationIDAndRemoveFromSuperview() {
        restorationIdentifier = nil
        removeFromSuperview()
    }
    
    func pinOnAllSidesToSuperview() {
        guard let superview = superview else {
            fatalError("addview to superview first")
        }
        
        contentMode = .scaleAspectFit
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }
    
    func pinOnAllSidesToSuperview(biggerBy inset:CGFloat) {
        guard let superview = superview else {
            fatalError("addview to superview first")
        }
        
        contentMode = .scaleAspectFit
        translatesAutoresizingMaskIntoConstraints = false
        
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: -inset).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: inset).isActive = true
        topAnchor.constraint(equalTo: superview.topAnchor, constant: -inset).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: inset).isActive = true
    }
    
    ///leading trailing top bottom insets
    func pinOnAllSidesToSuperview(biggerBy lttbInsets:(CGFloat, CGFloat, CGFloat, CGFloat)) {
        guard let superview = superview else {
            fatalError("addview to superview first")
        }
        
        contentMode = .scaleAspectFit
        translatesAutoresizingMaskIntoConstraints = false
        
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: lttbInsets.0).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: lttbInsets.1).isActive = true
        topAnchor.constraint(equalTo: superview.topAnchor, constant: lttbInsets.2).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: lttbInsets.3).isActive = true
    }
    
    // MARK: - animations
    func scaleAnimate(_ duration:TimeInterval = 4.0, _ spring:CGFloat = 0.1, _ scale:CGFloat = 0.8, _ delay: TimeInterval = 0.0, random:Bool) {
        
        let scales = [0.8, 0.9, 0.95, CGFloat(1.10), 1.20, 1.25, 1.30, 1.35, 1.40, CGFloat(1.10), 1.20, 1.25, 1.30, 1.35, 1.40]
        let springs = [CGFloat(0.1), 0.2, 0.3, 0.4, 0.08, 0.09]
        
        let duration:TimeInterval = 4.0 /* second */
        let _scale:CGFloat = random ? scales[scales.randomIndex] : scale
        let delay:TimeInterval = 0.0
        let _spring:CGFloat = random ? springs[springs.randomIndex] : spring
        
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: spring, initialSpringVelocity: 0.0,
                       options: [.curveEaseInOut, .allowUserInteraction]) { [weak self] in
            
            /* animation */
            self?.transform = CGAffineTransform(scaleX: _scale, y: _scale)
            
        } completion: {
            [weak self] animationFinishedBeforeCompletionCalled in
            
            UIView.animate(withDuration: 2.5*duration, delay: delay,
                           usingSpringWithDamping: _spring,
                           initialSpringVelocity: 0.0,
                           options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseIn]) {
                
                self?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }
    }
    
    func blink(_ blink:Bool, hide:Bool = true) {
        if blink {
            UIView.animate(withDuration: 1.2, delay: 0.0, options: [.repeat, .autoreverse]) {
                [weak self] in
                self?.alpha = 1
            } completion: {
                [weak self] _ in
                UIView.animate(withDuration: 1.2, delay: 0.0, options: [.repeat, .autoreverse]) {
                    self?.alpha = hide ? 0 : 0.45
                }
            }
        }
        
        else { self.alpha = 0 }
    }
    
    ///okButton in the DurationPicker animates like that
    func pulsateAnimate(maximumScale:CGFloat = 1.05, duration:CGFloat = 10.0) {
        UIView.animateKeyframes(withDuration: duration, delay: 0,
                                options: [.autoreverse, .repeat, .allowUserInteraction,
                                          .beginFromCurrentState, .calculationModePaced]) {
            [weak self] in
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                self?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                self?.transform = CGAffineTransform(scaleX: maximumScale, y: maximumScale)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                self?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                self?.transform = CGAffineTransform(scaleX: 1.025, y: 1.025)
            }
        }
    }
    
    // MARK: - methods used all the time
    /// add a view  in the middle of a superview
    func addSubviewInTheCenter(_ view:UIView) {
        let originX = (bounds.width - view.bounds.width)/2
        let originY = (bounds.height - view.bounds.height)/2
        view.frame.origin = CGPoint(x: originX, y: originY)
        
        self.addSubview(view)
    }
    
    /// add an image in the middle of a superview
    func addImageInTheCenter(_ image:UIImage, contentMode:ContentMode = .scaleAspectFit) {
        let imageView = UIImageView(image: image)
        let originX = (bounds.width - imageView.bounds.width)/2
        let originY = (bounds.height - imageView.bounds.height)/2

        let origin = CGPoint(x: originX, y: originY)
        imageView.frame.origin = origin
        imageView.contentMode = contentMode
        
        addSubview(imageView)
    }
    
    // MARK: - properties
    ///any view that is on screen  /part of a VC.view hierarchy/  will have its window property set
    var isOnscreen:Bool {return window != nil}
    
    // MARK: - initializer
    convenience init(origin:CGPoint = .zero, width:CGFloat, height:CFloat) {
        self.init(frame: CGRect(origin: origin, size: CGSize(width: width, height: CGFloat(height))))
    }
    
    // MARK: - for theory purposes
    ///shows and hides SafeArea's LayoutGuide https://1.bp.blogspot.com/-nKGb8plVgd8/Wdir-wLm6tI/AAAAAAAADmo/z3G6lWBlomASUtRJ6COYYKPdPC6KdMlBACLcBGAs/s1600/safe_area.png
    @available(iOS 11.0, *) /*means code for iOS 11 and above (including 11.0.1 and 11.1, etc)*/
    func toggleSafeArea() {
        if (subviews.contains {$0.restorationIdentifier == "pinkView"}) {
            //remove pinkView
            subviews.forEach {if ($0.restorationIdentifier == "pinkView") {$0.removeFromSuperview()}}
        } else {
            let pinkView = UIView(frame: bounds)
            pinkView.restorationIdentifier = "pinkView"
            pinkView.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1).withAlphaComponent(0.5)
            insertSubview(pinkView, at: 0)
            
            pinkView.translatesAutoresizingMaskIntoConstraints = false //if you want to add constraints manually
            
            //now you can add constraints manually. no danger of generating constraint conflicts
            pinkView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
            pinkView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pinkView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
            pinkView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        }
    }
    
    var isDarkModeOn:Bool {
        traitCollection.userInterfaceStyle == .dark ? true : false
    }
    
    // MARK: - better understanding theory
    
    func addDropshadow(_ add:Bool, color:UIColor = UIColor.black) {
        layer.shadowOpacity = (add && !isDarkModeOn) ? 0.5 : 0.0
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 5.0
        layer.shadowColor = color.cgColor
    }
    
    func addShadow(color:UIColor = UIColor(named: "darkGray")!.withAlphaComponent(0.2)) {
        if !isDarkModeOn {
            layer.shadowOffset = CGSize(width: 1, height: 1)
            layer.shadowOpacity = 1
            layer.shadowColor = color.cgColor
        } else {
            layer.shadowOpacity = 0
            layer.shadowColor = nil
        }
    }
    
    //dimiss keyboard by tapping outside the text field
    func setupKillKeyboard(){
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(killKeyboard(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    @objc private func killKeyboard(_ sender:UITapGestureRecognizer) { endEditing(true) }
    
}

public extension UIScrollView {
    /// take a larger image and place it inside a scrollView. you can specify if you want it centered
    func embed(_ image:UIImage, isImageCentered:Bool) {
        //most important property for a scrollView
        self.contentSize = image.size
        
        let imageView = UIImageView(image: image)
        imageView.bounds.size = image.size
        if isImageCentered {
            let offsetX = (contentSize.width - bounds.width)/2
            let offsetY = (contentSize.height - bounds.height)/2
            contentOffset = CGPoint(x: offsetX, y: offsetY)
        }
        addSubview(imageView)
        
        /*if you also want the scrollView to be zoomable
         1. set maxim/minimumZoomScale
         2. set scrollViewDelegate
         3. implement viewForZooming (usually return the imageView itself (ex: scroolView.subviews.first))*/
    }
    
    ///  zoomable scrollViews  need: 1. zoom scales (min and max)  and 2. a delegate
    /// - Parameters:
    ///   - minZoom: how small you want the view to appear when zooming out
    ///   - maxZoom: set to 1.0 by default so that an image doesn't look pixelated when you zoom in on it
    ///   - delegate: usually a view controller. do not forget to implement viewForZooming(...)  method! and return the view that you want to zoom on
    func setupZooming(minimum minZoom:CGFloat, maximum maxZoom:CGFloat = 1.0, delegate:UIScrollViewDelegate) {
        maximumZoomScale = maxZoom
        minimumZoomScale = minZoom
        self.delegate = delegate
    }
}

public extension UIViewController {
    ///any VC that has its root view on screen will have its root view's window property set
    var amIOnScreen:Bool {return view.window != nil}
}

public extension Array {
    /// there is a better method provided by Apple to shuffle an array, I'm sure, but this is a little experiment :) I haven't tested the method, so be careful!
    mutating func shuffledArray() {
        var shuffledArray = [Element]()
        
        while !self.isEmpty {
            let randomIndex = arc4random_uniform(UInt32(self.count - 1))
            shuffledArray.append(self.remove(at: Int(randomIndex)))
        }
        self = shuffledArray
    }
}

@available(iOS 8.2, *)
public extension UILabel {
    
struct UserInfo {
        let title:String
        let comment:String
        
        public init(title:String, comment:String){
            /*pizda mă-tii!!!!*/
            self.title = title
            self.comment = comment
        }
    }
    
    enum Style {
        case explain
        case alert
        case other
    }
}
