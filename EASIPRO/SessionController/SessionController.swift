//
//  SessionController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART




public protocol SessionProtocol : class {
    
    associatedtype PROMeasureObjectType
    
    associatedtype PROResultObjectType
    
    var measures: [PROMeasureObjectType]? { get set }
    
    var practitioner: Practitioner? { get }
    
    var patient: Patient { get }
    
    var onMeasureCancellation: ((_ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    var onMeasureCompletion: ((_ result: PROResultObjectType?, _ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    func prepareSessionContainer(callback: @escaping ((_ container: UIViewController?, _ error: Error?) -> Void))
}

open class SessionController2: NSObject, SessionProtocol {
    

    
    public typealias PROMeasureObjectType = PROMeasure2

    public typealias PROResultObjectType = Observation
    
    public var measures: [PROMeasure2]?
    
    public var practitioner: Practitioner?
    
    public var patient: Patient
    
    public var onMeasureCancellation: ((PROMeasure2?) -> Void)?

    public var onMeasureCompletion: ((Observation?, PROMeasure2?) -> Void)?
    
    open func prepareSessionContainer(callback: @escaping ((UIViewController?, Error?) -> Void)) {
        
    }
    
    required public init(patient: Patient, measures: [PROMeasure2], practitioner : Practitioner?) {
        self.patient = patient
        self.measures = measures
        self.practitioner = practitioner
    }
	
	open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
        var views : [UIViewController] = taskViewControllers
		let practitionerContext = SMARTManager.shared.usageMode == .Practitioner
        if  practitionerContext {
            let verifyController = PatientVerificationController(patient: patient)
            views.insert(verifyController, at: 0)
        }
		let sessionNC = SessionNavigationController(views: views, reversed: true)
		sessionNC.shouldVerifyAfter = practitionerContext
		return sessionNC
	}
}

open class SessionNavigationController: UINavigationController, UINavigationControllerDelegate {
	
	var shouldVerifyAfter: Bool = false
	
	func superDismiss(animated: Bool, completion: (() -> Void)? = nil) {
		super.dismiss(animated: animated, completion: completion)
	}
		
	open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		
		if viewControllers.count < 2 && shouldVerifyAfter {
			dismissWithDeviceLock()
		}
		else {
			super.dismiss(animated: flag, completion: completion)
		}
	}
	
	open override func popViewController(animated: Bool) -> UIViewController? {
		
		if viewControllers.count < 2 && shouldVerifyAfter {
			dismissWithDeviceLock()
		}
		else {
			super.popViewController(animated: animated)
		}
		return nil
	}
	
	func dismissWithDeviceLock() {
		LocalAuth.verifyDeviceUser("Practitioner Verification Required\nPlease Handover device to Practitioner.\n") { [weak self] (success, error) in
			if success {
				self?.superDismiss(animated: true)
			}
		}
	}
	
	convenience init(views: [UIViewController], reversed: Bool = false) {
		self.init()
		setViewControllers( reversed ? views.reversed() : views, animated: false)
		setNavigationBarHidden(true, animated: false)
		delegate = self
	}
	
	public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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
