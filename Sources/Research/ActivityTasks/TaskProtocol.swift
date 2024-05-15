//
//  TaskProtocol.swift
//  SMARTMarkers
//
//  Created by raheel on 3/30/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public protocol StudyTaskResultType {
    
    init(_ instrumentResult: InstrumentResult)
}
    
public protocol ActivityTaskProtocol {
    
    var identifer: String? { get }
    
    var lastAttempt: TaskAttempt? { get }
    
    var attempts: [TaskAttempt] { get }

    func serialize() throws -> [String: Any]
    
    func populate(from serialized: [String: Any]) throws
    
    func createSession(callback: @escaping ((_ viewController: UIViewController?, _ error: Error?) -> Void))
    
}
public protocol StudyTaskDelegate: AnyObject {
    
    /// Asks receiver if the task can begin. This is called before generating a `Session` controller
    func canBegin(task: StudyTaskProtocol, participant: any Participant) -> Bool
    
    /// Notifies upon completion of task
    func taskDidConclude(generating data: [DomainResource]?, for task: StudyTaskProtocol, attempt: SMARTMarkers.TaskAttempt)
    
    /// Should Submit  to Server?
    func canSubmitToServer(task: StudyTaskProtocol, participant: any Participant) -> Bool
}

public protocol StudyTaskProtocol {
    
    /// Delegate notifying receivers
    var delegate: StudyTaskDelegate? { get set }
    
    /// Persistor to save data
//    var persistor: (any DataPersistor)? { get }
    
    /// Task identifier
    var id: String { get set }
    
    /// Task  Categorical Identifier
    var categoricalIdentifier: String { get set }
    
    /// Study Task title
    var title: String { get set }
    
    /// Study Task subtitle
    var subTitle: String? { get set }
    
    /// Generated data after task completion. Always points to the most recently completed
    var generatedData: [DomainResource]? { get set }
    
    /// `TaskController` for the actual activity
    var activities: [ActivityTaskProtocol]? { get set }

    /// `TaskController` intended for an instructional instrument
    var instructionTask: ActivityTaskProtocol? { get set }
    
    /// for study
    var study: Study? { get }
        
    /// handle generated data
    func handleGeneratedData()
    
    /// Creates a task session ViewController  for presentation
    func createSession(callback: @escaping ((_ viewController: UIViewController?, _ error: Error?) -> Void))
    
    /// For storing generated data; JSON
    func serialize(errors: inout [Error]?) throws -> [String: Any]?
    
    /// Populating data from Storage
    func populate(from serialized: [String: Any]) throws
    
}


extension StudyTaskProtocol {
    
    public var lastAttempt: TaskAttempt? {
        activities?.compactMap({ $0.lastAttempt }).last
    }
    
}
