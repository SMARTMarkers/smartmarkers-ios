//
//  SessionController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 15/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


public protocol SessionDelegate: class {
    
    func sessionEnded(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?)
    
    func sessionShouldBegin(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?) -> Bool
    
}

open class SessionController: NSObject {
    
    public let identifier: String
    
    var measures: [PDController]
    
    var patient: Patient?
    
    var server: Server?
    
    var verifyUser: Bool
    
    var errors: [Error]?
    
    public init(_ measures: [PDController], patient: Patient?, server: Server?, verifyUser: Bool = false) {
        
        self.identifier = UUID().uuidString
        self.measures = measures
        self.patient = patient
        self.verifyUser = verifyUser
        self.server = server
    }
    
    weak var delegate: SessionDelegate?
    
    public var onCancellation: ((_ proMeasure: PDController) -> Void)?
    
    public var onCompletion: (( _ session: SessionController) -> Void)?
    
    
    open func prepareController(callback: @escaping ((_ controller: UIViewController?, _ error: Error?) -> Void)) {
        
        var taskControllers = [ORKTaskViewController]()
        
        let group = DispatchGroup()
        var errors = [Error]()
        for measure in measures {
            
//            measure._sessionController = self
            group.enter()
            measure.prepareSession { (taskViewController, error) in
                if let tvc = taskViewController {
                    taskControllers.append(tvc)
                }
                else {
                    if let err = error {
                        errors.append(err)
                    }
                }
                group.leave()
            }
        }
        
        
        
        
        group.notify(queue: .main) {
            if taskControllers.count > 0 {
                
                // SubmissionTask
                if let _ = self.patient, let _ = self.server {
                    let submissionTask = SubmissionTaskController(self)
                    submissionTask.delegate = self
                    taskControllers.append(submissionTask)
                }
                
                let sessionNavigationController = self.sessionContainerController(for: taskControllers)
                callback(sessionNavigationController, (errors.isEmpty) ? nil : SMError.sessionCreatedWithMissingTasks)
            }
            else {
                callback(nil, SMError.sessionMissingTask)
            }
        }
    }
    
    open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
        
        var views : [UIViewController] = taskViewControllers
        if  verifyUser, let patient = patient {
            let verifyController = PatientVerificationController(patient: patient)
            views.insert(verifyController, at: 0)
        }
        
        let container = SessionNavigationController(views: views, reversed: true, verifyUser: verifyUser, session: self)
//        ({
//            self.onCompletion?(self)
//        }))
        
        return container
    }

}


/*
public protocol SessionControllerTaskDelegate : class  {
    
    func sessionEnded(_ taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?)
    
    func sessionShouldBegin(taskViewController: ORKTaskViewController, PRO: PROMeasure) -> Bool

}


public protocol SessionProtocol : class {
    
    associatedtype PROMeasureObjectType : PROMeasureProtocol
    
    var measures: [PROMeasureObjectType] { get set }
    
    var practitioner: Practitioner? { get }
    
    var patient: Patient? { get }
    
    var taskDelegate: SessionControllerTaskDelegate? { get set }
    
    var onMeasureCancellation: ((_ measure: PROMeasureObjectType?) -> Void)?  { get set }
    
    func prepareSessionContainer(callback: @escaping ((_ container: UIViewController?, _ error: Error?) -> Void))
    

}


open class SessionControll: NSObject, SessionProtocol {
    
    public typealias PROMeasureObjectType = PROMeasure

    public var measures: [PROMeasure]
    
    public var onMeasureCancellation: ((PROMeasure?) -> Void)?
    
    public var onCompletion: ((SessionController) -> Void)?
    
    public var practitioner: Practitioner?
    
    public var patient: Patient?
    
    public var server: Server?
    
    public var shouldVerify = false
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    open func prepareSessionContainer(callback: @escaping ((UIViewController?, Error?) -> Void)) {
        
        var taskControllers = [ORKTaskViewController]()

        let group = DispatchGroup()
        var errors = [Error]()
        for measure in measures {
            group.enter()
            measure.prepareSession { (taskViewController, error) in
                if let tvc = taskViewController {
                    taskControllers.append(tvc)
                }
                else {
                    if let err = error {
                        errors.append(err)
                    }
                }
                group.leave()
            }
        }
        
        
        
        
        group.notify(queue: .main) {
            if taskControllers.count > 0 {
                
                // SubmissionTask
                if let _ = self.patient, let _ = self.server {
                    let submissionTask = SubmissionTaskController(self)
                    submissionTask.delegate = self
                    taskControllers.append(submissionTask)
                }
                
                let sessionNavigationController = self.sessionContainerController(for: taskControllers)
                callback(sessionNavigationController, (errors.isEmpty) ? nil : SMError.sessionCreatedWithMissingTasks)
            }
            else {
                callback(nil, SMError.sessionMissingTask)
            }
        }
        
        
    }
    
    required public init(patient: Patient?, measures: [PROMeasure], practitioner : Practitioner?, server : SMART.Server?) {
        self.patient = patient
        self.measures = measures
        self.server = server
        self.measures.forEach({ (m) in
            m.patient = patient
            m.server = server
        })
        self.practitioner = practitioner
    }
    
	
	open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> UINavigationController {
        
        var views : [UIViewController] = taskViewControllers
        if  shouldVerify, let patient = patient {
            let verifyController = PatientVerificationController(patient: patient)
            views.insert(verifyController, at: 0)
        }
        
        
        let sessionNC = SessionNavigationController(views: views, reversed: true, shouldVerify: shouldVerify, sessionEnded: ({
            self.onCompletion?(self)
        }))
        
		return sessionNC
	}
}


*/

extension SessionController: ORKTaskViewControllerDelegate {
    
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.navigationController?.popViewController(animated: true)
    }
}
