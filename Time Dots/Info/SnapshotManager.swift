import UIKit

// TODO: handle 2 to 0 transition
/*use it when you do vc transitions, start from level 0, stop using it when you return to level 0*/
class SnapshotManager {
    typealias Context = UIViewControllerContextTransitioning
    
    public enum TransitionSituation {
        case push
        case pop
        case popIsCancelled
    }
    
    public func handle(_ situation:TransitionSituation, _ transitionContext:Context) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else { return }
        
        switch situation {
        case .push: /*insert*/
            if let fromViewSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true) {
                toVC.view.insertSubview(fromViewSnapshot, at: 0)
            }
            
        case .pop: /*remove*/
            guard let snapshot = fromVC.view.subviews.first else {return}
            snapshot.removeFromSuperview()
            
        case .popIsCancelled: /*insert*/
            if let toViewSnapshot = toVC.view.snapshotView(afterScreenUpdates: true) {
                fromVC.view.insertSubview(toViewSnapshot, at: 0)
            }
        }
    }
}
