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


public protocol SessionControllerTaskDelegate : class  {
    
    func sessionEnded(_ taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?)
    
    func sessionShouldBegin(taskViewController: ORKTaskViewController, PRO: PROMeasure) -> Bool

}


public protocol SessionProtocol : class {
    
    associatedtype PROMeasureObjectType : PROMeasureProtocol
    
    var measures: [PROMeasureObjectType]? { get set }
    
    var practitioner: Practitioner? { get }
    
    var patient: Patient? { get }
    
    var taskDelegate: SessionControllerTaskDelegate? { get set }
    
    var onMeasureCancellation: ((_ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
//    var onMeasureCompletion: ((_ result: PROResultObjectType?, _ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    func prepareSessionContainer(callback: @escaping ((_ container: UIViewController?, _ error: Error?) -> Void))
    

}

open class SessionController: NSObject, SessionProtocol {
    
    public typealias PROMeasureObjectType = PROMeasure

    public var measures: [PROMeasure]?
    
    public var onMeasureCancellation: ((PROMeasure?) -> Void)?
    
    public var practitioner: Practitioner?
    
    public var patient: Patient?
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    open func prepareSessionContainer(callback: @escaping ((UIViewController?, Error?) -> Void)) {
        
        guard let measures = measures else  {
            return
        }
        var taskControllers = [ORKTaskViewController]()

        let group = DispatchGroup()
        
        for measure in measures {
            group.enter()
            measure.prepareSession { (taskViewController, error) in
                print(taskViewController as Any)
                if let tvc = taskViewController {
                    taskControllers.append(tvc)
                }
                group.leave()
            }
        }
      
        
        group.notify(queue: .main) {
            if taskControllers.count > 0 {
                let sessionNavigationController = self.sessionContainerController(for: taskControllers)
                callback(sessionNavigationController, nil)
            }
            else {
                callback(nil, nil)
            }
        }
        
        
    }
    
    required public init(patient: Patient?, measures: [PROMeasure]?, practitioner : Practitioner?) {
        self.patient = patient
        self.measures = measures
        self.measures?.forEach({ (m) in
            m.patient = patient
            m.client = SMARTManager.shared.client
        })
        self.practitioner = practitioner
    }
	
	open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
        var views : [UIViewController] = taskViewControllers
		let practitionerContext = SMARTManager.shared.usageMode == .Practitioner
        if  practitionerContext {
            let verifyController = PatientVerificationController(patient: patient!)
            views.insert(verifyController, at: 0)
        }
		let sessionNC = SessionNavigationController(views: views, reversed: true)
		sessionNC.shouldVerifyAfter = practitionerContext
		return sessionNC
	}
}



