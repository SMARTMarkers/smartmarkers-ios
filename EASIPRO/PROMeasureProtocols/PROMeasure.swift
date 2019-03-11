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
    
    associatedtype RequestType

    var request: RequestType? { get set }
    
    var instrument: InstrumentProtocol? { get set }
    
    func instrument(callback: @escaping ((_ instrument: InstrumentProtocol?, _ error: Error?) -> Void))
 
    var server: Server? { get }
    
    var patient: Patient? { get set }
    
    func fetchAll(callback : ((_ success: Bool, _ error: Error?) -> Void)?)
    
    var taskDelegate: SessionControllerTaskDelegate? { get set }
    
    func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
}

open class PROMeasure : NSObject, PROMeasureProtocol {

    public typealias RequestType = RequestProtocol
    
    public var patient: Patient?
    
    public var request: RequestType?
    
    public var instrument: InstrumentProtocol? {
        didSet {
            results = PROResults(resultRelations: instrument?.ip_resultingFhirResourceType, patient)
        }
    }
    
    public var results: PROResults?
    
    public var schedule: Schedule?
    
    public var teststatus: String = "begin"
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    public weak var server: Server? = SMARTManager.shared.client.server
    
    public convenience init(request: RequestProtocol?) {
        self.init()
        self.request = request
        self.schedule = request?.rq_schedule
    }
    
    
    
    open func instrument(callback: @escaping ((_ instrument: InstrumentProtocol?, _ error: Error?) -> Void)) {        
        if let instr = self.instrument {
            callback(instr, nil)
            return
        }
        request?.rq_instrumentResolve(callback: callback)
    }
    
    public convenience init(instrument: InstrumentProtocol?) {
        self.init()
        self.instrument = instrument

    }
    
    public override init() { }
    

    
    
    public class func Fetch<T:DomainResource & RequestProtocol>(requestType: T.Type, server: Server, options: [String:String]? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {

        var searchParams =  T.rq_fetchParameters ?? [String:String]()
        
        if let options = options {
            for (k,v) in options {
                searchParams[k] = v
            }
        }

      
        T.Requests(from: server, options: searchParams) { (requests, error) in
            if let requests = requests {
                let proMeasures = requests.map{ PROMeasure(request: $0) }
                callback(proMeasures, nil)
            }
            if let error = error {
                callback(nil, error)
            }
        }
    }
    
    public class func Fetch<T:DomainResource & InstrumentProtocol>(instrumentType: T.Type, server: Server, options: [String:String]? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {
        T.Instruments(from: server, options: options) { (instruments, error) in
            if let instruments = instruments {
                let proMeasures = instruments.map { PROMeasure(instrument: $0) }
                callback(proMeasures, nil)
            }
            if let error = error {
                callback(nil, error)
            }
        }
        
    }
    
    public func fetchAll(callback : ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let srv = server else {
            callback?(false, SMError.promeasureServerNotSet)
            return
        }
        
        guard let results = results else {
            callback?(false, SMError.promeasureFetchLinkedResources)
            return
        }
        
        results.fetchResults(server: srv, searchParams: nil) { (results, error) in
            callback?(results != nil, error)
        }
    }
    
    public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = self.instrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        
        instrument.ip_taskController(for: self) { (taskViewController, error) in
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

            let bundle =  instrument?.ip_generateResponse(from: taskViewController.result, task: taskViewController.task!)

            //TODO: Request Protocol constraint to DomainResource
            let prescribingReference = try (request as? ProcedureRequest)?.asRelativeReference()
            let patientReference = try patient.asRelativeReference()
            for entry in bundle?.entry ?? [] {
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
                    let results = rbundle.entry?.filter { $0.resource is ResultType }.map{ $0.resource as! ResultType }
                    if let results = results {
                        self?.results?.add(resources: results)
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
