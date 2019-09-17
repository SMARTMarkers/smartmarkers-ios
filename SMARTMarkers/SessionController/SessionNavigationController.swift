//
//  SessionNavigationController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/10/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation


open class SessionNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    var shouldVerifyAfter: Bool = false
    
    var sessionEnded: (() -> Void)?
    
    
    func superDismiss(animated: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: animated, completion: completion)
    }
    
    
    open override func popViewController(animated: Bool) -> UIViewController? {

        if viewControllers.count <= 1 {
            if shouldVerifyAfter {
                dismissWithDeviceLock(animated: animated)
            }
            else {
                super.dismiss(animated: animated, completion: sessionEnded)
            }
            return nil
        }
        else {
            return super.popViewController(animated: animated)
        }
    }
    
    func dismissWithDeviceLock(animated: Bool) {
        LocalAuth.verifyDeviceUser("Practitioner Verification Required\nPlease Handover device to Practitioner.\n") { [weak self] (success, error) in
            if success {
                DispatchQueue.main.async {
                        self?.superDismiss(animated: animated)
                }
            }
        }
    }
    
    convenience init(views: [UIViewController], reversed: Bool = false, shouldVerify: Bool = false, sessionEnded: (() -> Void)?) {
        self.init()
        self.sessionEnded = sessionEnded
        setViewControllers( reversed ? views.reversed() : views, animated: false)
        setNavigationBarHidden(true, animated: false)
        delegate = self
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .pop {
            return Animator()
        }
        return nil
    }
}




class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.4
    
    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let fromView = transitionContext.view(forKey: .from)!
        containerView.insertSubview(toView, at: 0)
        toView.frame = containerView.frame
        fromView.layer.shadowColor = UIColor.black.cgColor
        fromView.layer.shadowOpacity = 0.5
        fromView.layer.shadowOffset = CGSize.zero
        fromView.layer.shadowRadius = 10
        UIView.animate(withDuration: duration, animations: {
            fromView.transform = CGAffineTransform(translationX: 0, y: toView.frame.size.height * -1);
        }, completion: { _ in
            transitionContext.completeTransition(true)
        } )
    }
}
