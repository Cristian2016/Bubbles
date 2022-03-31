//
//  Slide Animation Controllers.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 09.12.2021.
//  Used for custom VC transitions for swipe left and right on a time bubble cell

import UIKit

class PresentAnimationController:NSObject, UIViewControllerAnimatedTransitioning {
    
    enum SlideDirection {
        case leftToRight
        case rightToLeft
    }
    
    let slideDirection:SlideDirection
    init(slideDirection:SlideDirection, duration:TimeInterval = 0.6) {
        self.slideDirection = slideDirection
        self.transitionDuration = duration
    }
    
    let transitionDuration:TimeInterval
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            //inform system that animation failed
            transitionContext.completeTransition(false)
            
            return
        }
        
        //destination view is NOT inside container
        //source view is inside container already
        let container = transitionContext.containerView
        container.addSubview(toVC.view)
        
        let translationX:CGFloat
        switch slideDirection {
        case .leftToRight:
            translationX = -toVC.view.frame.width
        case .rightToLeft:
            translationX = toVC.view.frame.width
        }
        
        toVC.view.transform = CGAffineTransform(translationX: translationX, y: 0)
        toVC.view.addDropshadow(true)
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration) {
            toVC.view.transform = .identity
        } completion: { animationCompletedBeforeHandlerCall in
            if let /* fromView */snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) {
                //use restoration ID to remove snapshot on dismiss transition
                snapshot.restorationIdentifier = "snapshot"
                container.insertSubview(snapshot, at: 1)
            }
            
            //inform system animation completed successfully
            transitionContext.completeTransition(true)
        }
    }
}

class DismissAnimationController:NSObject, UIViewControllerAnimatedTransitioning {
    
    enum SlideDirection {
        case leftToRight
        case rightToLeft
    }
    
    let slideDirection:SlideDirection
    init(slideDirection:SlideDirection) {
        self.slideDirection = slideDirection
    }
    
    let transitionDuration = TimeInterval(0.5)
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            //inform system that animation failed
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        container.insertSubview(toVC.view, at: 0)
        
        let translationX:CGFloat
        switch slideDirection {
        case .leftToRight:
            translationX = fromVC.view.frame.width
        case .rightToLeft:
            translationX = -fromVC.view.frame.width
        }
                
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration) {
            container.subviews.filter { $0.restorationIdentifier == "snapshot" }.first?.removeFromSuperview()
            fromVC.view.transform = CGAffineTransform(translationX: translationX, y: 0)
        } completion: { animationCompletedBeforeHandlerCall in
            fromVC.view.addDropshadow(false)
            //inform system animation completed successfully
            transitionContext.completeTransition(true)
        }
    }
}
