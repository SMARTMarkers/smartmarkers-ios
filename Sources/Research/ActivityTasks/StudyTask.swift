//
//  StudyTask.swift
//  SMARTMarkers
//
//  Created by raheel on 4/6/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



    
open class StudyTask {
    
    public let InterpeterType: (TaskResultInterpreterProtocol).Type?
    public var taskControllers: [TaskController]?
    public unowned let activity: StudyActivityDefinition
    public internal(set) var interpreted: (any TaskResultInterpreterProtocol)?
    public internal(set) var instruments: [(any Instrument)]?
    
    public var lastAttempt: TaskAttempt? {
        result?.result.last?.metric
    }
    public weak var delegate: ActivityTaskDelegate?
    
    private func assignResult<T: TaskResultInterpreterProtocol>(interpreterType: T.Type, for result: StudyTaskResult) -> T {
        T.init(result: result)
    }
    
    public var result: StudyTaskResult? {
        didSet {
            if let result, let iType = InterpeterType {
                interpreted = assignResult(interpreterType: iType.self, for: result)
            }
        }
    }
    
    public var onTaskCompletion: ActivityTaskCompletionCallback?

    var session: SessionController?

    open var id: String {
        activity.id
    }
    open var title: String? {
        activity.title
    }
    open var subTitle: String? {
        activity.subTitle
    }
    open var relationships: [StudyActivityRelationship]? {
        self.activity.relationships
    }
    open var fulfilled: Bool {
        interpreted?.fulfilled() ?? (result?.hasData == true)
    }
    var applicable: Bool = false
    open var repeatable: Bool = false
    open var isConditional: Bool {
        activity.resource.condition != nil
    }
    
    

    // initialize with definition of the task (StudyActivity)
    public init(_ activity: StudyActivityDefinition, interpreterType: TaskResultInterpreterProtocol.Type?, delegate: ActivityTaskDelegate? = nil) {
        self.activity = activity
        self.InterpeterType = interpreterType
        self.delegate = delegate
    }
    
    ///
    open func isApplicable() -> Bool {
        true
    }
    open func isRepeatable() -> Bool {
        false
    }
    
    
    /// Prepares task; calls `StudyActivityDefinition.resolveInstrument()`
    open func prepare(callback: @escaping (( _ error: Error?) -> Void)) {
        self.activity.resolveInstrument(delegate: delegate) { error in
            callback(error)
        }
    }
    
    
    
    /// Creates a instance of `ORKTaskViewCntroller`
    open func createSession(presenterOptions: InstrumentPresenterOptions?, callback: @escaping ((_ view: UIViewController?, _ error: Error?) -> Void)) {
       
        guard let instruments = activity.instruments(delegate: delegate) else {
            callback(nil, SMError.undefined(description: "Instruments not found"))
            return
        }
        
        taskControllers = instruments.map({ i in
            let t = TaskController(instrument: i)
            t.presenterOptions = presenterOptions
            return t
        })
        
        
        session = SessionController(taskControllers!, patient: nil, server: nil)
        
        session?.onConclusion = { [weak self] sessionResult in
            
            if sessionResult.discarded != true {
                self?.result = sessionResult
            }
            
            callOnMainThread {
                self?.onTaskCompletion?(sessionResult)
            }
        }
        
        session?.prepareController(callback: callback)
    }
    
   
    
    /// For storing generated data; JSON
    open func serialize(errors: inout [Error]?) throws -> [String: Any]? {
        
        guard let sessionResult = result, let dict = try sessionResult.serialize(errors: &errors) else { return nil }
        
     
        
        let json: [String: Any] = ["categoricalIdentifier": id,
                                   "taskId": id,
                                   "version": "a",
                                   "result": dict]
        return json
    }
    
    
    open func old_populate(from serialized: [String: Any]) throws {
        
        do {
            
            var context = FHIRInstantiationContext(strict: false)
            let taskId = serialized["taskId"] as? String ?? "task_id"
            
            var taskMetrics = [TaskAttempt]()
            if let taskData = serialized["taskData"] as? [[String: Any]] {
                for data in taskData {
                    if let attempts = data["attempts"] as? [[String: Any]] {
                        let taskAttempts = try attempts
                            .map ({ try TaskAttempt(serialized: $0) })
                        taskMetrics.append(contentsOf: taskAttempts)
                    }
                }
            }
            taskMetrics.sort(by: { $0.startTime > $1.startTime })
            
            var fhirResources = [DomainResource]()
            if let bundl = serialized["generatedData"] as? [[String: Any]] {
                let resources = bundl.compactMap { json -> DomainResource? in
                    let resource = FHIRAbstractResource.instantiate(from: json, owner: nil, context: &context)
                    if let resource = resource as? DomainResource {
                        return resource
                    }
                    return nil
                }
                fhirResources.append(contentsOf: resources)
            }
            
            //1. get all instrumentIdentifiers
            let instrumentIds = Array(Set(taskMetrics.map({ $0.taskId })))
            print(instrumentIds)
            let i_count = instrumentIds.count
            
            if i_count > 1 {
                // risk enhancers
                // for each instrument, get their report by identifier.
                //
                var instrumentBundles = [InstrumentResult]()
                for i_id in instrumentIds {
                    // get metric
                    let tms = taskMetrics
                        .filter({ $0.taskId == i_id && $0.state == .completedWithSuccess })
                        .first
                    // get generatedData
                    #if DEBUG
                    fhirResources.forEach({ print(($0 as? Report)?.rp_code?.sm_searchableToken()) })
                    #endif
                    let fhir = fhirResources.filter({ ($0 as? Report)?.rp_code?.sm_searchableToken() == i_id })
                    if fhir.isEmpty {
                        continue
                    }
                    
                    let instrumentResult = InstrumentResult(taskId: i_id, bundle: SMART.Bundle.sm_with(fhir), metric: tms!)
                    
                    instrumentBundles.append(instrumentResult)
                }
                
                if instrumentBundles.count > 0 {
                    self.result = StudyTaskResult(sessionId: taskId, result: instrumentBundles)
                }
            }
            else {
                let tms = taskMetrics
                    .filter({ $0.state == .completedWithSuccess })
                    .first
                
                
                if let tms, fhirResources.count > 0 {
                    let instrumentResult = InstrumentResult(
                        taskId: instrumentIds.first!,
                        bundle: SMART.Bundle.sm_with(fhirResources),
                        metric: tms)
                    let result = StudyTaskResult(sessionId: taskId, result: [instrumentResult])
                    return self.result = result
                }
            }
            
            
//            if id == "risk_enhancers" {
//                fatalError()
//            }
        }
        catch {
            smLog(error)
        }
    }

    
    
    /// Populating data from Storage
    open func populate(from serialized: [String: Any]) throws {
       
        guard let _ = serialized["version"] as? String else {
            try old_populate(from: serialized)
            return
        }
        
        guard let sessionResults_dict = serialized["result"] as? [String: Any] else {
            return
        }
        
        self.result = try StudyTaskResult(json: sessionResults_dict)
    }
    
    
    // MARK: DEPENDENT TASKS TO DETERMINE STATUS
    
    /// List of Tasks required to be completed before this task
    lazy var requiresCompletionOfTaskIds: [(String, Range?)]? = {
        if let relatedAction = activity.relatedAction {
            let afterEnd = relatedAction.filter({ $0.relationship == .afterEnd })
            for relatedAction in afterEnd {
                
                let actionId = relatedAction.actionId?.string
                let offsetRange = relatedAction.offsetRange
            }
            return afterEnd.isEmpty ? nil : relatedAction.map {  ($0.actionId!.string, $0.offsetRange) }
            
        }
        return nil
    }()
    
    /// Conditions that need to be fulfilled before this task can be activated
    lazy var requiresSatisfyingApplicabilityConditions: Bool = {
        activity.applicabilityConditions() != nil
    }()
    
}



extension StudyTask: Equatable {
    public static func == (lhs: StudyTask, rhs: StudyTask) -> Bool {
        lhs.id == rhs.id
    }
}
