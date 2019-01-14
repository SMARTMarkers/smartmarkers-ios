//
//  PROMeasure.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/27/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit




public protocol PROMeasureProtocol : class {
    
    associatedtype PrescribingClassType : PRBaseProtocol
    
    associatedtype EventClassType : EventResource
    
    associatedtype InstrumentClassType : InstrumentResourceProtocol
    
    var prescribingResource: PrescribingClassType? { get set }
    
    var event : EventClassType? { get set }
    
    var orderedInstrument : InstrumentClassType? { get set }
    
    var server: Server? { get }
    
    var patient: Patient? { get set }
    
    func fetchAll(callback : ((_ success: Bool, _ error: Error?) -> Void)?)
    
    var taskDelegate: SessionControllerTaskDelegate? { get set }
    
    func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
}

open class PROMeasure : NSObject, PROMeasureProtocol {
    
    public var teststatus: String = "begin"
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    public typealias EventClassType = EventResource
    
    public typealias InstrumentClassType = InstrumentResource
    
    public var prescribingResource: PrescribingResource?
    
    public var scores : [Double]?
    
    public var event : EventResource?
    
    public var measurements: ResourceFetch<Observation>?
    
    public var responses: ResourceFetch<QuestionnaireResponse>?
    
    open var orderedInstrument : InstrumentClassType?
    
    public weak var server: Server? = SMARTManager.shared.client.server
    
    public convenience init(_ _prescriberResource: PrescribingResource?) {
        self.init()
        self.prescribingResource = _prescriberResource
        
        var params = [String:String]()
        if let prReference = try? _prescriberResource?.resource?.asRelativeReference() {
            params["based-on"] = prReference?.reference?.string
            
            if let pReference = try? patient?.asRelativeReference() {
                params["patient"] = pReference?.reference?.string
            }
            
            //params["code"] = "http://loinc.org|2339-0"
            measurements = ResourceFetch(Observation.self, param: params)
            responses = ResourceFetch(QuestionnaireResponse.self, param: params)
        }
    }
    
    public convenience init(_ _instrument: InstrumentResource?) {
        self.init()
        self.orderedInstrument = _instrument
        //::: TODO- configure responses/measurements based on Instrument.code or Instrument.identifier
        if let questionnaire = _instrument?.instrument as? Questionnaire {
            responses = ResourceFetch(QuestionnaireResponse.self, param: ["questionnaire" : questionnaire.id!.string])
        }
        else {
            responses = ResourceFetch(QuestionnaireResponse.self, param: nil)
        }
    }
    
    public override init() { }
    
    public var patient: Patient?
    
    public class func getPrescriber<T: PrescriberType>(server: Server, Ptype: T.Type, param: [String: String]?, callback: @escaping (([PROMeasure]?, Error?) -> Void)) {
        Ptype.Get(server: server, param: param) { (prescribingResources, error) in
            if let prescribingResources = prescribingResources {
                let measures = prescribingResources.map { PROMeasure(PrescribingResource($0)) }
                callback(measures, nil)
            }
            else {
                
                callback(nil, error)
            }
        }
    }
    
    public func fetchAll(callback : ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let srv = server else {
            callback?(false, SMError.promeasureServerNotSet)
            return
        }
        
        let group = DispatchGroup()
        var errorInFetch = false
        if let measurements = measurements {
            group.enter()
            measurements.getEvents(server: srv, callback: { (records, error) in
                errorInFetch = (error != nil)
                if let records = records {
                    self.prescribingResource?.schedule?.update(with: records.map{$0.date})
                }
                group.leave()
            })
        }
        
        
        if let pastResponses = responses {
            group.enter()
            pastResponses.getEvents(server: srv) { (_, error) in
                errorInFetch = (error != nil)
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            callback?(true, (errorInFetch) ? SMError.promeasureFetchLinkedResources : nil)
        }
        
    }
    
    
    public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = orderedInstrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        instrument.taskController(for: self) { (taskViewController, error) in
            taskViewController?.delegate = self
            callback(taskViewController, error)
        }
    }
    
    // :::TODO: UpdatePrescriberStatus after the conclusion of a session
    public func updatePrescribingStatus() {
        self.teststatus = "complete"
    }
    
    
    
    
    
}


extension PROMeasure : ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error serror: Error?) {
        

        
        guard
            reason == .completed,
            let patient = patient,
            let server = server
            else
        {
            print("error: One or All of: No-patient/No-server/NotCompleted")
            self.taskDelegate?.sessionEnded(taskViewController, reason: reason, error: serror)
            taskViewController.navigationController?.popViewController(animated: true)
            return
        }
        
        
        var zerror = serror

        do {
            let bundle = try orderedInstrument!.generateResponse(from: taskViewController.result, task: taskViewController.task!)
            let prescribingReference = try prescribingResource?.resource?.asRelativeReference()
            let patientReference = try patient.asRelativeReference()
            for entry in bundle.entry! {
                if let answers = entry.resource as? QuestionnaireResponse {
                    answers.subject = patientReference
                    if let r = prescribingReference {
                        var basedOns = answers.basedOn ?? [Reference]()
                        basedOns.append(r)
                        answers.basedOn = basedOns
                    }
                }
                if let observation = entry.resource as? Observation {
                    observation.subject = patientReference
                    if let r = prescribingReference {
                        var basedOns = observation.basedOn ?? [Reference]()
                        basedOns.append(r)
                        observation.basedOn = basedOns
                    }
                }
            }
            
            
            let handler = FHIRJSONRequestHandler(.POST, resource: bundle)
            let headers = FHIRRequestHeaders([.prefer: "return=representation"])
            handler.add(headers: headers)
            
            let semaphore = DispatchSemaphore(value: 0)
            server.performRequest(against: "//", handler: handler, callback: { [weak self] (response) in
                if let response = response as? FHIRServerJSONResponse, let json = response.json , let rbundle = try? SMART.Bundle(json: json) {
                    let observations = rbundle.entry?.filter{ $0.resource is Observation}.map{ $0.resource as! Observation}
                    if let observations = observations {
                        self?.measurements?.add(resources: observations)
                    }
                    let answers = rbundle.entry?.filter{ $0.resource is QuestionnaireResponse}.map{ $0.resource as! QuestionnaireResponse}
                    if let answers = answers {
                        self?.responses?.add(resources: answers)
                    }
                    self?.updatePrescribingStatus()
                }
                semaphore.signal()
            })
            semaphore.wait()
        }
        catch {
            zerror = error
        }
        
        taskDelegate?.sessionEnded(taskViewController, reason: reason, error: zerror)
        taskViewController.navigationController?.popViewController(animated: true)
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, recorder: ORKRecorder, didFailWithError error: Error) {
        
    }
    
    public func taskViewControllerShouldConfirmCancel(_ taskViewController: ORKTaskViewController) -> Bool {
        return true
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        
        return true
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        let _title = patient?.humanName ?? "PRO Measure"
        stepViewController.title = _title
    }
    
    
    
}
