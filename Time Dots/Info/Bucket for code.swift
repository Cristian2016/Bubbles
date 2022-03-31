import UIKit
import CoreHaptics


public struct ViewHelper {
    ///view.center is or not in the middle of the other view
    static func isViewInTheMiddleOfItsSuperView(_ view:UIView, superview:UIView) -> Bool {
        guard view.superview != nil else { return false }
        
        let superviewMidXandY = CGPoint(x:  superview.frame.height/2, y: superview.frame.width/2)
        return view.center == superviewMidXandY
    }
    static func describeSubviews(for view:UIView) {
        guard !view.subviews.isEmpty else { return }
        var restorationIDs = [String?]()
        view.subviews.forEach {restorationIDs.append($0.restorationIdentifier)}
    }
    static func disableUserInteraction(_ flag:Bool, for views:[UIView]) {
        views.forEach{$0.isUserInteractionEnabled = flag ? false : true}
    }
    static func blocksGesturesForViewsUnderneath(_ flag:Bool, view:UIView?) {
        if let view = view {
            view.isUserInteractionEnabled = flag ? true : false
        }
    }
    static func getSubview(with restorationID:String?, in superview:UIView) -> UIView? {
        superview.subviews.filter {$0.restorationIdentifier == restorationID}.first
    }
    static func pinViewToTheTopOfScreenIgnoringStatusBarHeight(ignore:Bool, _ view:UIView) {
        guard let superview = view.superview else { return }
        
            let sbHeight =
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.statusBarManager?.statusBarFrame.height
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: superview.topAnchor, constant: ignore ? (-(sbHeight ?? 0)) : 0).isActive = true
    }
    ///of device
    static func statusBarHeight() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.statusBarManager?.statusBarFrame.height ?? 0
    }
    
    private init(){}
}

extension UIView {
    ///enter offset between -1 and 1. 0 means no offset for that axis
    func addSubViewWithPercentageOffsetFromCenter(_ view:UIView, _ offset:CGPoint) {
        let width = self.frame.width
        let height = self.frame.height
        
        let offsetX = width * offset.x
        let offsetY = height * offset.y
        
        addSubviewInTheCenter(view)
        view.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
    }
    //when circle selected
    func reactToTap(_ scale:CGFloat = 1.15, _ hapticStyle:UIImpactFeedbackGenerator.FeedbackStyle = .heavy, _ duration:TimeInterval = 0.05) {
        
        UserFeedback.triggerSingleHaptic(hapticStyle)
        
        UIView.animate(withDuration: duration) {[weak self] in
            self?.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: {[weak self] _ in
            UIView.animate(withDuration: 0.4) {
                self?.transform = .identity
            }
        }
    }
}

extension UIImageView {
    func customize(for situation:InfoPictureSituation) {
        
        let imageName = isDarkModeOn ?
            situation.rawValue + "_" + "\(Int(UIScreen.main.bounds.height))" + " inverted" :
            situation.rawValue + "_" + "\(Int(UIScreen.main.bounds.height))"
        
        let image = UIImage(named: imageName)

        self.image = image
        self.restorationIdentifier = imageName
        self.contentMode = .scaleAspectFit
        self.isUserInteractionEnabled = true
    }
}

extension DateFormatter {
    ///Time Bubbles date style: Tue, 15 Feb. 22
    static let tbDateStyle: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.locale = Locale(identifier: "us_US")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "E, d MMM. yy"
        
        return dateFormatter
    }()
    
    ///Time Bubbles time style: 17:39:25
    static let tbTimeStyle: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.locale = Locale.current
        dateFormatter.calendar = Calendar.current
        dateFormatter.timeStyle = .medium
        
        return dateFormatter
    }()
}

extension Array {
    var penultimate:Element? {
        guard count >= 2 else { return nil }
        return self[count - 2]
    }
}
