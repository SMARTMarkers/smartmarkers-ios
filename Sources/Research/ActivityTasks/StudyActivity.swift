//
//  StudyActivity.swift
//  SMARTMarkers
//
//  Created by raheel on 3/31/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART




open class StudyActivityRelationship {
    
    public let relationship: PlanDefinitionActionRelatedAction
    public init(_ rel: PlanDefinitionActionRelatedAction) {
        self.relationship = rel
    }
    
}

public protocol ActivityTaskDelegate: InstrumentResolver {
   
    func resolve(condition: [PlanDefinitionActionCondition], for activity: StudyActivityDefinition) -> Bool
}

public struct DataRequired {
    
    let fhirType: ResourceType
    let valueSet: [ValueSet]
    
    func codes<T: DomainResource>() -> (code: [String], system: String, fhirResource: T.Type)? {
        nil
    }
    
    init(_ dataRequirement: DataRequirement) throws {
        
        guard let valueSet = dataRequirement.codeFilter?.compactMap ({ $0.valueSet?.resolved(ValueSet.self) }) else {
            throw SMError.undefined(description: "DataRequirement.valueSet cannot be resolved")
        }
        
        self.valueSet = valueSet
        self.fhirType = ResourceType(rawValue: dataRequirement.type!.string)!
    }
}
open class StudyActivityDefinition {
    
    public let id: String
    public unowned let resource: PlanDefinitionAction

    public var definition: ActivityDefinition?
    public var relationships: [StudyActivityRelationship]?
    public var output: [DataRequired]?
    public var subActions: [StudyActivityDefinition]?
    
    public var relatedAction: [PlanDefinitionActionRelatedAction]? {
        resource.relatedAction
    }
    
    public var instrument: Instrument?
    public internal(set) var request: Request?
    
    public var identifier: [Identifier]? {
        definition?.identifier
    }
    
    public var code: [Coding]? {
        definition?.code?.coding
    }
    
    public var title: String? {
        definition?.title?.string ?? resource.title?.string
    }
    
    public var subTitle: String? {
        definition?.subtitle?.string ?? resource.description_fhir?.string
    }
    
    public var name: String? {
        definition?.name?.string ?? resource.title?.string
    }
    
    public var purpose: String? {
        definition?.purpose?.string
    }
    
    public var participantType: String? {
        definition?.participant?.first?.type?.rawValue ?? resource.participant?.first?.type?.rawValue
    }
    
    public init(_ action: PlanDefinitionAction, activityDelegate: ActivityTaskDelegate? = nil) throws {
        
        guard let id = action.id?.string else {
            throw SMError.undefined(description: "PlanDefintionAction.id is needed")
        }
        
        self.id = id
        self.resource = action
        
        self.output = try action.output?.compactMap({ try DataRequired($0) })
        
        self.relationships = action.relatedAction?.compactMap{ $0 }.map{ StudyActivityRelationship($0) }
        
        
        if var subActions = action.action {
            var definitions = [StudyActivityDefinition]()
            while let subAction = subActions.popLast() {
                let studyActivityDef = try StudyActivityDefinition(subAction)
                definitions.append(studyActivityDef)
            }
            self.subActions = definitions
        }
        else {
            self.definition = action
                .definitionCanonical?
                .resolved(ActivityDefinition.self)
        }
        
        if self.definition == nil && self.subActions == nil {
            let err = SMError.undefined(description: "Undefined ActionDefinition for PlanDefinitionAction=\(id)")
            smLog(err)
            throw err
        }
    }
   
    /// check if the instrument is applicable, as per the defined conditions if any
    private func isApplicable(activityResolver: ActivityTaskDelegate?) -> Bool {
       
        guard let condition = resource.condition else {
            return true
        }
        
        return activityResolver?.resolve(condition: condition, for: self) ?? true
    }
    
   
    /// Returns instrument artifacts
    func instruments(delegate: ActivityTaskDelegate?) -> [Instrument]? {

        if var subs = subActions {
            var insts =  [Instrument]()
            while let sub = subs.popLast() {
                if isApplicable(activityResolver: delegate) {
                    let ins = sub.instruments(delegate: delegate)
                    insts.append(contentsOf: ins ?? [])
                }
            }
            return insts.isEmpty ? nil : insts
        }
        else {
            if isApplicable(activityResolver: delegate) {
                if let i = self.instrument {
                    return [i]
                }
            }
        }
        
        return nil
    }
    
    typealias InstrumentCallbackError = ((_ instrument: (any Instrument)?, _ error: Error?) -> Void)
    
    func _deriveInstrument(from resolver: ActivityTaskDelegate, callback: @escaping InstrumentCallbackError) {
        if let code, let identifier {
            resolver.resolveInstrument(for: code, identifier: identifier, callback: callback)
        }
        else {
            callback(nil, nil)
        }
    }
    
    func _deriveInstrument(from relatedArtifact: RelatedArtifact, callback: @escaping InstrumentCallbackError) {
        
        guard let resource = relatedArtifact.resource else {
            callback(nil, SMError.undefined(description: "Cannot prepare, no instrument; relatedArtifact.resource is nil"))
            return
        }
        
        guard let questionnaire = resource.resolved(Questionnaire.self) else {
            callback(nil, SMError.undefined(description: "Cannot prepare activity; Questionnaire cannot be resolved for resource\(resource)"))
            return
        }
        
        callback(questionnaire, nil)
    }
    
    func _deriveSMARTMarkersInstrument(code: String, callback: @escaping InstrumentCallbackError) {
        if let instr = Instruments.Code(code) {
            let config = (self.output != nil) ? ["output": self.output] : nil
            instr.sm_configure(config)
            callback(instr, nil)
        }
        else {
            callback(nil, SMError.undefined(description: "Unknown SMARTMarkers.Instrument.code=\(code)"))
        }
    }

    /// Resolves instrument artifacts to use for conducting the task
    open func resolveInstrument(delegate: ActivityTaskDelegate?, callback: @escaping ((_ error: Error?) -> Void)) {
        
        if var subAction = subActions {
            let grp = DispatchGroup()
            var errors = [Error?]()
            while let sub = subAction.popLast() {
                grp.enter()
                sub.resolveInstrument(delegate: delegate) { err in
                    smLog(" >> [SAD] taskForDef=\(self.id)")
                    errors.append(err)
                    grp.leave()
                }
            }
            grp.notify(queue: DispatchQueue.global(qos: .userInteractive)) {
                if errors.compactMap({ $0 }).count > 0 {
                    callback(SMError.undefined(description: ">> Prepareing\(self.id): bunch of errors=\(errors)"))
                }
                else {
                    callback(nil)
                }
            }
        } 
        else {
            
            
            let sem = DispatchSemaphore(value: 0)
            
            if let delegate {
                _deriveInstrument(from: delegate) { [weak self] instrument, error in
                    self?.instrument = instrument
                    sem.signal()
                }
                sem.wait()
            }
            guard self.instrument == nil else {
                callback(nil)
                return
            }
            
            if let relatedArtifact = definition?.relatedArtifact?.filter({ $0.type == .dependsOn }).first {
                _deriveInstrument(from: relatedArtifact) { instrument, error in
                    self.instrument = instrument
                    callback(error)
                }
           }
            else if let coding = definition?.code?.coding?.first, let cod = coding.code?.string  {
                if coding.system?.absoluteString == SMARTMarkers.InstrumentSystem {
                    _deriveSMARTMarkersInstrument(code: cod) { instrument, error in
                        self.instrument = instrument
                        callback(error)
                    }
                }
                else {
                    callback(SMError.instrumentUnresolved("Cannot resolve instrument"))
                }
            }
            else {
                callback(SMError.undefined(description: "Cannot prepare actvitiy.Instrument; PlanDefinitionAction has no referenmce \(self.id)"))
            }
        }
    }
    
    
    func resolveRequest() throws -> (any Request)? {
        
        
        guard let def = definition, let kind = def.kind else {
            smLog("No request to be created")
            return nil
        }
        
        let schedule: TaskSchedule?
        if let period = def.timingPeriod {
            schedule = TaskSchedule(occurancePeriod: period)
        }
        else if let time = def.timingTiming {
            schedule = TaskSchedule(occuranceTiming: time)
        }
        else {
            schedule = TaskSchedule(dueDate: Date())
        }
        
        let requestResource = kind.sm_CreateRequest()
        
        
        
        
        
        return requestResource
    }
    
    func applicabilityConditions() -> [PlanDefinitionActionCondition]? {
        if let conds = resource.condition?.filter({ $0.kind == .applicability }) {
            return conds.isEmpty == true ? nil : conds
        }
        return nil
    }
    
    
}
// --------------------------------------------
// ---- TASK SECTION --------------------------
// --------------------------------------------
// --------------------------------------------

public typealias ActivityTaskCompletionCallback = (( _ sessionResult: StudyTaskResult) -> Void)

extension RequestResourceType {
    
    func sm_CreateRequest() -> (any Request)? {
        switch self {
        case .serviceRequest:
            return SMART.ServiceRequest()
        case .task:
            return SMART.Task()
        default:
            return nil
        }
    }
}
