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
    
    associatedtype PROMeasureScoreObjectType
    
    var measures: [PROMeasureObjectType]? { get set }
    
    var practitioner: Practitioner { get }
    
    var patient: Patient { get }
    
    var onMeasureFailure: ((_ result: PROMeasureScoreObjectType?, _ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    var onMeasureCompletion: ((_ result: PROMeasureScoreObjectType?, _ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    /// Callback handler for Completed Session (for All PROMeasures)
    var onSessionCompletion: ((_ result: PROMeasureScoreObjectType?, _ measures: [PROMeasureScoreObjectType]?) -> Void)? { get set }
    
    
    /// Callback handler: Called when session is interrupted
    var onCancellation: ((_ viewController: ORKTaskViewController, _ error: Error?) -> Void)? { get set }
    
    func prepareSessionContainer(callback: @escaping ((_ container: UIViewController?, _ error: Error?) -> Void))
}

open class SessionController2: SessionProtocol {

    
    public typealias PROMeasureObjectType = PROMeasure2

    public typealias PROMeasureScoreObjectType = AnyObject
    
    public var measures: [PROMeasure2]?
    
    public var practitioner: Practitioner
    
    public var patient: Patient
    
    public var onMeasureFailure: ((AnyObject?, PROMeasure2?) -> Void)?
    
    public var onMeasureCompletion: ((AnyObject?, PROMeasure2?) -> Void)?
    
    public var onSessionCompletion: ((AnyObject?, [AnyObject]?) -> Void)?
    
    public var onCancellation: ((ORKTaskViewController, Error?) -> Void)?
    
    public func prepareSessionContainer(callback: @escaping ((UIViewController?, Error?) -> Void)) {
        
    }
    
    required public init(patient: Patient, measures: [PROMeasure2]?, practitioner : Practitioner) {
        self.patient = patient
        self.measures = measures
        self.practitioner = practitioner
    }
    

    
    
}



open class SessionController: NSObject, UITableViewDelegate, ORKTaskViewControllerDelegate, UINavigationControllerDelegate {
    
    
    
    /// Patient Resource
	public final var patient : Patient {
		didSet {
			verifiedPatient = false
		}
	}
    
    /// Practitioner
    public final var practitioner : Practitioner
    
    /// Questionnaires to do
    open var measures: [PROMeasure]? = nil
	
	/// checks if patient has been verified by the patient
	open var verifiedPatient : Bool = false
    
    /// ResearchKit's TaskViewControllers.
    public final var taskViewControllers: [ORKTaskViewController]?
    
    /// Callback handler: Called when all questionnaires are completed
    public final var onMeasureFailure: ((_ result: AnyObject?, _ measure: PROMeasure?) -> Void)?

    public final var onMeasureCompletion: ((_ result: AnyObject?, _ measure: PROMeasure?) -> Void)?
    
    /// Callback handler for Completed Session (for All PROMeasures)
    public final var onSessionCompletion: ((_ result: AnyObject?, _ measures: [PROMeasure]?) -> Void)?
    
    /// Callback handler: Called when session is interrupted
    public final var onCancellation: ((_ viewController: ORKTaskViewController, _ error: Error?) -> Void)?
    
    
    /// if not nil; generates `Observation`
    open func resultFromTaskViewController(_ taskViewController: ORKTaskViewController) -> String? {
        return nil
    }
	
    
    
    required public init(patient: Patient, measures: [PROMeasure]?, practitioner : Practitioner) {
        self.patient = patient
        self.measures = measures
        self.practitioner = practitioner
    }
    
    open func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        print("-> EASIPRO: PREPARING SESSION")
        
        
    }
    
    
    open func prepareSessions(callback: @escaping (([ORKTaskViewController]?, Error?) -> Void)) {
        
        print("-> EASIPRO: PREPARING SESSION[S]")
    
    }
    
    open func prepareSessionContainer(callback: @escaping ((_ container: UIViewController?, _ error: Error?) -> Void)) {

        
        
        
        
    }
    
    
    open class func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
        let navigationController = UINavigationController()
        navigationController.setViewControllers(taskViewControllers.reversed(), animated: false)
        navigationController.setNavigationBarHidden(true, animated: false)
        return navigationController
    }
    
    open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
		let verifyController = PatientVerificationController(patient: patient)
		var views : [UIViewController] = taskViewControllers
		views.insert(verifyController, at: 0)
		let navigationController = UINavigationController()
		navigationController.setViewControllers(views.reversed(), animated: false)
		navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.delegate = self
        return navigationController
    }
	
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        print("here")
    }
	
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		
		if operation == .pop {
			return Animator()
		}
		return nil
    }
	
	
	
}





class Animator: NSObject, UIViewControllerAnimatedTransitioning {
	
	let duration = 0.5
	
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
