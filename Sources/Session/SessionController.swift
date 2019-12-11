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

/**
 Instances can conform to `SessionControllerDelegate` to be notified about task session conclusion and reason
 */
public protocol SessionControllerDelegate: class {
    
    func sessionEnded(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?)
    
    func sessionShouldBegin(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?) -> Bool
    
}

/**
 `SessionController` for Multiple Tasks
 
 SessionController is to create a single unified user session to generate data from multiple tasks. Can also submit generated FHIR Bundles to the `FHIR Server` for a given `Patient`
 */
open class SessionController: NSObject {
    
    /// Session identifier; a UUID string
    public let identifier: String
    
    /// Task controllers
    public internal(set) var tasks: [TaskController]
    
    /// `Patient` for which a session is created; optional
    public internal(set) var patient: Patient?
    
    /// `FHIR Server` for submission of the results
    public internal(set) var server: Server?
    
    /// Delegate to inform task completion progress
    weak var delegate: SessionControllerDelegate?
    
    /// Callback to call if a task has been cancelled
    public var onCancellation: ((_ task: TaskController) -> Void)?
    
    /// Callback to call when all tasks have concluded
    public var onConclusion: (( _ session: SessionController) -> Void)?
    
    /// Optional `Patient` verification;
    let verifyUser: Bool
    
    /// Collection of errors
    private lazy var _errors: [Error] = {
        return [Error]()
    }()
    
    
    public var errors: [Error] {
        return _errors
    }
    
    /**
     Designated Initializer
     
     - parameter tasks:         Array of `TaskControllers` that need to be administered
     - parameter patient:       optional `Patient`; needed for submission to `FHIR Server`
     - parameter server:        optional `Server`; needed for submission to `FHIR Server`
     - parameter verifyUser:    optional; Set true for initial patient check
    */
    public init(_ tasks: [TaskController], patient: Patient?, server: Server?, verifyUser: Bool = false) {
        self.identifier = UUID().uuidString
        self.tasks = tasks
        self.patient = patient
        self.verifyUser = verifyUser
        self.server = server
    }
    
    /**
     Prepares a `SessionViewController with all child `ORKTaskViewControllers`
     
     
    */
    open func prepareController(callback: @escaping ((_ controller: SessionViewController?, _ error: Error?) -> Void)) {
        
        var viewControllers = [ORKTaskViewController]()
        
        let group = DispatchGroup()
        var errors = [Error]()
        for task in tasks {
            
            group.enter()
            task.prepareSession { (taskViewController, error) in
                if let tvc = taskViewController {
                    viewControllers.append(tvc)
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
            if viewControllers.count > 0 {
                
                // SubmissionTask Module appended when a server and patient is found
                if let _ = self.patient, let _ = self.server {
                    let submissionTask = SubmissionTaskController(self)
                    viewControllers.append(submissionTask)
                }
                
                let sessionView = self.sessionContainerController(for: viewControllers)
                callback(sessionView, (errors.isEmpty) ? nil : SMError.sessionCreatedWithMissingTasks)
            }
            else {
                callback(nil, SMError.sessionMissingTask)
            }
        }
    }
    
    open func sessionContainerController(for taskViewControllers: [ORKTaskViewController]) -> SessionViewController {
        
        var views : [UIViewController] = taskViewControllers
        if  verifyUser, let patient = patient {
            let verifyController = MiniPatientVerificationController(patient: patient)
            views.insert(verifyController, at: 0)
        }
        
        let container = SessionViewController(views: views, reversed: true, verifyUser: verifyUser, session: self)
        container.modalPresentationStyle = .fullScreen

        return container
    }

}


extension SessionController: ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.navigationController?.popViewController(animated: true)
    }
}
