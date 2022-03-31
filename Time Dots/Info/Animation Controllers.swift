import UIKit
typealias Context = UIViewControllerContextTransitioning
typealias Transitioning = UIViewControllerAnimatedTransitioning
typealias NC = NavigationController

let levels = [VC.chronoTimers:0, VC.palette:1, VC.timerDuration:2, VC.detail:3]

//2 classes for custom VC transitions. one for push, the other for pop
class PushAnimator: NSObject, Transitioning {
    
    let snapshotManager:SnapshotManager
    
    init(with snapshotManager:SnapshotManager) {
        self.snapshotManager = snapshotManager
    }
    
    func transitionDuration(using transitionContext: Context?) -> TimeInterval { Duration.vcTransition }
    
    func animateTransition(using transitionContext: Context) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let toView = toVC.view
        else {
                //notifies the system the transition is NOT done
                transitionContext.completeTransition(false)
                return
        }
        
        /*prepare toView
         1. translate toView by its width to the left
         2. add to container view*/
        toView.transform = CGAffineTransform(translationX: -toView.frame.width, y: 0)
        toView.backgroundColor = .clear
        transitionContext.containerView.addSubview(toView)
        
        // MARK: DropShadow |-> before push transition
        UITweaks.toggleDropShadow(.on, for: toView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.transform = .identity
        }) { [weak self] (animationDidFinishBeforeCompletionCalled) in
            // MARK: SnapshotManager ->| after push transition
            /*call handle before completeTransition, else unwanted visual effect*/
            self?.snapshotManager.handle(.push, transitionContext)
            
            //notify the system: 'hey, transition done!'
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class PopAnimator: NSObject, Transitioning {
    let snapshotManager:SnapshotManager
    
    init(with snapshotManager:SnapshotManager) {
        self.snapshotManager = snapshotManager
    }
    
    func transitionDuration(using transitionContext: Context?) -> TimeInterval {
    Duration.vcTransition
}
    
    func animateTransition(using transitionContext: Context) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let toView = toVC.view,
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromView = fromVC.view else { return }
        
        transitionContext.containerView.insertSubview(toView, at: 0)
        
        // MARK: SnapshotManager |-> before pop transition
        snapshotManager.handle(.pop, transitionContext)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.transform = CGAffineTransform(translationX: -fromView.frame.width, y: 0)
        }) { [weak self] (animationDidFinishBeforeCompletionCalled) in
            if transitionContext.transitionWasCancelled {
                // MARK: SnapshotManager pop transition cancelled
                self?.snapshotManager.handle(.popIsCancelled, transitionContext)
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
