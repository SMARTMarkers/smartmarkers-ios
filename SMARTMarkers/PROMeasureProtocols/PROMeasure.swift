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


public protocol InstrumentResolver: class {
    func resolveInstrument(from pro: PROMeasure) -> InstrumentProtocol?
}

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
    
    public weak var instrumentResolver: InstrumentResolver?

    public typealias RequestType = RequestProtocol
    
    public var patient: Patient?
    
    public var request: RequestType?
    
    public var oauthSettings: [String:Any]? 
    
    public var instrument: InstrumentProtocol? {
        didSet {
            results = PROResults(resultRelations: instrument?.ip_resultingFhirResourceType, patient)
        }
    }
    
    public var results: PROResults?
    
    public var schedule: Schedule?
    
    public var teststatus: String = ""
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    public weak var server: Server? = SMARTManager.shared.client.server
    
    public static var instrumentLibrary: [InstrumentProtocol]?
    
    public convenience init(request: RequestProtocol) {
        self.init()
        self.request = request
        self.schedule = request.rq_schedule
        
        // Default
        self.results = PROResults(resultRelations: [
            PROFhirLinkRelationship(Observation.self,           ["based-on": request.rq_identifier]),
            PROFhirLinkRelationship(QuestionnaireResponse.self, ["based-on": request.rq_identifier])
            ], patient)
    }
    
    
    
    open func instrument(callback: @escaping ((_ instrument: InstrumentProtocol?, _ error: Error?) -> Void)) {        
        
        if let instr = self.instrument {
            callback(instr, nil)
            return
        }
        
        if let instrumentResolver = instrumentResolver, let instr = instrumentResolver.resolveInstrument(from: self) {
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
    

    
    
    public class func Fetch<T:DomainResource & RequestProtocol>(requestType: T.Type, server: Server, options: [String:String]? = nil, instrumentResolver: InstrumentResolver? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {

        var searchParams =  T.rq_fetchParameters ?? [String:String]()
        
        if let options = options {
            for (k,v) in options {
                searchParams[k] = v
            }
        }
      
        T.Requests(from: server, options: searchParams) { (requests, error) in
            if let requests = requests {
                let proMeasures = requests.map({ (request) -> PROMeasure in
                    let pro = PROMeasure(request: request)
                    pro.instrumentResolver = instrumentResolver
                    return pro
                })
                callback(proMeasures, nil)
            }
            callback(nil, error)
        }
    }
    
    public class func Fetch<T:DomainResource & InstrumentProtocol>(instrumentType: T.Type, server: Server, options: [String:String]? = nil, callback: @escaping (([PROMeasure]? , Error?) -> Void)) {
        T.Instruments(from: server, options: options) { (instruments, error) in
            if let instruments = instruments {
                let proMeasures = instruments.map { PROMeasure(instrument: $0) }
                callback(proMeasures, nil)
            }
            callback(nil, error)
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


    public func updateRequest(_ _results: [ResultType]?, callback: @escaping ((_ success: Bool) -> Void)) {
        guard request != nil, let res = _results else {
            return
        }
        if let completed = schedule?.update(with: res.map{ $0.rp_date }) {
            request?.rq_updated(completed, callback:callback)
        }
    }
    
    
    public func generateAndSubmit(result: ORKTaskResult, task: ORKTask, callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        let bundle = instrument?.ip_generateResponse(from: result, task: task)
        
    }
   
    
}




extension PROMeasure : ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error serror: Error?) {
        
        // ***
        // Bug :Premature firing before conclusion step
        // ***
        let stepIdentifier = taskViewController.currentStepViewController!.step!.identifier
        if stepIdentifier.contains("range.of.motion") { return }
        // ***
        
        let bundle =  instrument?.ip_generateResponse(from: taskViewController.result, task: taskViewController.task!)
        
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


            //TODO: Request Protocol constraint to DomainResource
            let prescribingReference = try (request as? ServiceRequest)?.asRelativeReference()
            let patientReference = try patient.asRelativeReference()
            for entry in bundle?.entry ?? [] {
                
                //QuestionnaireResponse
                if let answers = entry.resource as? QuestionnaireResponse {
                    answers.subject = patientReference
                    if let r = prescribingReference {
                        var basedOns = answers.basedOn ?? [Reference]()
                        basedOns.append(r)
                        answers.basedOn = basedOns
                    }
                }
                
                //Observation
                if let observation = entry.resource as? Observation {
                    observation.subject = patientReference
                    if let r = prescribingReference {
                        var basedOns = observation.basedOn ?? [Reference]()
                        basedOns.append(r)
                        observation.basedOn = basedOns
                    }
                }
                
                //Binary
                if let binary = entry.resource as? Binary {
                    binary.securityContext = patientReference
                }
                
                //Media
                if let media = entry.resource as? Media {
                    media.subject = patientReference
                    if let reqReference = prescribingReference {
                        media.basedOn = [reqReference]
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
                    self?.updateRequest(results, callback: { (success) in
                        if success {
                            print("successfully udpated status")
                        }
                    })
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
        if stepViewController.title == nil {
            stepViewController.title = patient?.humanName ?? "Session #\(taskViewController.task!.identifier)"
        }
    }
    
    
    
}
