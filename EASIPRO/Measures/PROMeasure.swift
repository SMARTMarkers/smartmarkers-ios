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
    
    var client: Client? { get }
    
    var patient: Patient? { get set }
    
    func fetchAll(callback : ((_ success: Bool) -> Void)?)
    
    var taskDelegate: SessionControllerTaskDelegate? { get set }
    
    func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
}

open class PROMeasure : NSObject, PROMeasureProtocol {
    
    public weak var taskDelegate: SessionControllerTaskDelegate?
    
    public typealias EventClassType = EventResource
    
    public typealias InstrumentClassType = InstrumentResource
    
    public var prescribingResource: PrescribingResource?
    
    public var scores : [Double]?
    
    public var event : EventResource?
    
    public var measurements: ResourceFetch<Observation>?
    
    public var responses: ResourceFetch<QuestionnaireResponse>?
    
    open var orderedInstrument : InstrumentClassType?
    
    public weak var client: Client? = SMARTManager.shared.client
    
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
                print(error as Any)
                callback(nil, error)
            }
        }
    }
    
    public func fetchAll(callback : ((_ success: Bool) -> Void)?) {
        
        guard let srv = client?.server else {
            print("no server")
            callback?(false)
            return
        }
        
        let group = DispatchGroup()
        
        if let measurements = measurements {
            group.enter()
            measurements.getEvents(server: srv, callback: { (records, _) in
                if let records = records {
                    self.prescribingResource?.schedule?.update(with: records.map{$0.date})
                }
                group.leave()
            })
        }
        
        
        if let pastResponses = responses {
            group.enter()
            pastResponses.getEvents(server: srv) { (_, _) in
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            callback?(true)
        }
        
    }
    
    
    public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = orderedInstrument else {
            print("error:Instrument not identified")
            callback(nil, nil)
            return
        }
        instrument.instrument.rk_taskController(for: self) { (taskViewController, error) in
            if let taskViewController = taskViewController {
                taskViewController.delegate = self
                callback(taskViewController, nil)
            }
            else {
                print("error:")
                callback(nil, nil)
            }
        }
    }
    
    // :::TODO: UpdatePrescriberStatus after the conclusion of a session
    public func updatePrescribingStatus() {
        
    }
    
    
    
}


extension PROMeasure : ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        guard
            reason == .completed,
            let patient = patient,
            let server = client?.server,
            let bundle = orderedInstrument?.instrument.rk_generateResponse(from: taskViewController.result, task: taskViewController.task!)
            else
        {
            print("error: One or All of: No-patient/No-server/No-bundle-to-write/NotCompleted")
            self.taskDelegate?.sessionEnded(taskViewController, reason: reason, error: error)
            taskViewController.navigationController?.popViewController(animated: true)
            return
        }
        
        let group = DispatchGroup()
        
        do {
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
            group.enter()
            let headers = FHIRRequestHeaders([.prefer: "return=representation"])
            handler.add(headers: headers)
            server.performRequest(against: "//", handler: handler, callback: { (response ) in
                if let response = response as? FHIRServerJSONResponse, let json = response.json , let rbundle = try? SMART.Bundle.init(json: json) {
                    print(rbundle)
                    let observations = rbundle.entry?.filter{ $0.resource is Observation}.map{ $0.resource as! Observation}
                    if let observations = observations {
                        self.measurements?.add(resources: observations)
                    }
                    
                    let answers = rbundle.entry?.filter{ $0.resource is QuestionnaireResponse}.map{ $0.resource as! QuestionnaireResponse}
                    if let answers = answers {
                        self.responses?.add(resources: answers)
                    }
                    self.updatePrescribingStatus()
                }
                group.leave()
            })
            
        }
        catch {
            print(error)
        }
        group.notify(queue: .main) {
            self.taskDelegate?.sessionEnded(taskViewController, reason: reason, error: error)
            taskViewController.navigationController?.popViewController(animated: true)
        }
        
        
        
        
        
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

// LEGACY REFERENCE

/*
public enum PROMeasureStatus {
	case completed
	case aborted
	case cancelled
	case active
	case unknown
}

public enum PROSessionStatus : String {
    case upcoming               = "UPCOMING"
    case due                    = "DUE TODAY"
    case planConcluded          = "CONCLUDED"
    case completedCurrent       = "COMPLETED CURRENT SLOT"
    case unknown                = "UNKNOWN"
}

*/
/*
public protocol PROMResourceProtocol {
    
    associatedtype T = Self
    
    static func Create(for patient: Patient, callback: @escaping (_ resource: [T]?, _ error: Error?) -> Void)
}


public protocol PROMProtocol {
	
	associatedtype PrescribingResourceType
	
	associatedtype MeasurementResourceType
	
	var prescribingResource : PrescribingResourceType? { get set }
	
	var measure: AnyObject? { get set }
	
	var measureStatus: PROMeasureStatus { get set }
	
	var results : [MeasurementResourceType]? { get set }
	
	var title : String { get set }
	
	var identifier : String { get set }
    
    var sessionStatus: PROSessionStatus { get set }
	
    
	static func FetchPrescribingResources(for patient: Patient, callback: @escaping (_ resource: [Self]?, _ error: Error?) -> Void)
    
	
	func fetchMeasurementResources(callback: ((_ success: Bool) -> Void)?)
	
	func status(of prescriber: PrescribingResourceType) -> PROMeasureStatus
}




public final class PROMeasure2 : PROMProtocol {
	
	public typealias MeasurementResource = Observation
	
	public typealias PrescribingResource = ProcedureRequest

	public var prescribingResource: ProcedureRequest? {
		didSet {
			if let pr = prescribingResource {
				self.schedule = Schedule.initialise(prescribing: pr)
				self.measureStatus   = status(of: pr)
				// todo: in appropriate use of status
				filterObservations()
                assignInstrumentCode()
			}
		}
	}
    
    func assignInstrumentCode() {
        
    }
    
    public var prescriber : String? {
        get {
            return (prescribingResource?.requester?.agent?.display?.string.uppercased())
        }
    }
	
	public var measure: AnyObject?
	
	public var measureStatus: PROMeasureStatus = .unknown
    
    public var sessionStatus: PROSessionStatus = .unknown
    
    public var scores : [Double]?
	
	public var results: [Observation]? {
        didSet {
            results = results?.sorted { $0.effectiveDateTime!.nsDate < $1.effectiveDateTime!.nsDate }
            filterObservations()
        }
	}
	
	public var title: String
	
	public var identifier: String
	
	public var schedule: Schedule?
	
	public init(title: String, identifier: String) {
		self.title = title
		self.identifier = identifier
	}
    
    public static func FetchPrescribingResources(for patient: Patient, smartManager: SMARTManager, callback: @escaping (_ measures: [PROMeasure2]?, _ error: Error?) -> Void) {
        //todo: expand search params to get survey category, promis identifiers etc..
        let searchParams = ["patient" : patient.id!.string]
        smartManager.search(type: ProcedureRequest.self, params: searchParams) { (resources, error) in
            if nil != error {
                print(error.debugDescription)
                callback(nil, error)
            }
            if let resources = resources {
                let promeasures = resources.map({ (procedureRequest) -> PROMeasure2 in
                    let title = procedureRequest.ep_titleCode ?? procedureRequest.ep_titleCategory ?? procedureRequest.id!.string
                    // Every PROMeasure = ProcedureRequest
                    let identifier = procedureRequest.id!.string
                    // TODO: standardize measureIdentifier
                    let prom = PROMeasure2(title: title, identifier: identifier)
                    prom.prescribingResource = procedureRequest
                    return prom
                })
                callback(promeasures, nil)
            }
            else {
                callback(nil, nil)
            }
            
        }
    }
	
	

	public static func FetchPrescribingResources(for patient: Patient, callback: @escaping (_ resource: [PROMeasure2]?, _ error: Error?) -> Void) {
        FetchPrescribingResources(for: patient, smartManager: SMARTManager.shared, callback: callback)
		
	}


	
	
	public func fetchMeasurementResources(callback:  ((Bool) -> Void)?) {

		guard let patient = SMARTManager.shared.patient, let pr = prescribingResource else {
			callback?(false)
			return
		}
		let param = ["patient" : patient.id!.string,
					 "based-on": pr.id!.string]
		SMARTManager.shared.search(type: Observation.self, params: param) { [weak self] (observations, error) in
			if nil != error {
				callback?(false)
			}
			self?.results = observations
			callback?(self?.results != nil)
			
		}
	}
	
	public func status(of prescriber: ProcedureRequest) -> PROMeasureStatus {
		
		guard let pstatus = prescriber.status else {
			return .unknown
		}
		switch pstatus {
			case .completed:
				return .completed
			case .cancelled:
				return .cancelled
			case .active:
				return .active
			default:
				return .unknown
		}
		

	}
    
    
    func filterObservations() {
        if let res = results {
            scores = res.map { Double($0.valueString!.string)! }
        }
        
        // if Scheduled, then check slots
        // TODO: associate results with slotIntervals
        // Each slot --->> [Observations]
        if let _ = schedule?.slots {
            
            
            
            
            
            
        }
        
        if measureStatus == .completed || measureStatus == .aborted {
            sessionStatus = .planConcluded
        } else if measureStatus == .active {
            // Compare Observations and things here:
            // Check if Current Slot is due
            let hasNext     = schedule?.nextSlot != nil
            let dueToday    = schedule?.currentSlot != nil
            let latestScore = results?.last?.effectiveDateTime?.nsDate
			
            
            if !dueToday && !hasNext { sessionStatus = .planConcluded }

            else if dueToday {
                if latestScore == nil { sessionStatus = .due }
				// TODO: add Frequency Matching.
				
                if let latestScore = latestScore, schedule!.currentSlot!.period.contains(latestScore) {
                    sessionStatus = (hasNext) ? .completedCurrent : .planConcluded
                } else {
                    sessionStatus = .due
                }
            }
            else if hasNext { sessionStatus = .upcoming }
            
            
            
            
        } else { sessionStatus = .unknown }
        
    }
	
	public static func Classify(proms: [PROMeasure2]?) -> [[String:Any]]? {
		
		var data = [[String:Any]]()

		if let dues = proms?.filter({ $0.sessionStatus ==  .due}), dues.count > 0 {
			data.append(["status" : "due", "data" : dues])
		}
		if let upcoming = proms?.filter({ $0.sessionStatus == .upcoming || $0.sessionStatus == .completedCurrent }), upcoming.count > 0 {
			data.append(["status" : "Upcoming", "data" : upcoming])
		}
		if let completed = proms?.filter({ $0.sessionStatus == .planConcluded }), completed.count > 0 {
			data.append(["status" : "Completed", "data" : completed])
		}
		
		return data
		
	}

}

extension PROMeasure2 : Equatable {
    
    public static func ==(lhs: PROMeasure2, rhs: PROMeasure2) -> Bool {
        return (lhs.identifier == rhs.identifier)
    }
}


public protocol PROPrescriberResourceProtocol {
    
    associatedtype PrescribingResourceType
    
    associatedtype MeasurementResourceType
    
    associatedtype EventResourceType
    
    var prescribingResource: PrescribingResourceType? { get set }
    
    var measurementResources : [MeasurementResourceType]? { get set }
    
    var eventResources : [EventResourceType]? { get set }
    
    var smartManager : SMARTManager { get }
    
    var prescriber : String? { get }
    
    
    init(pr: PrescribingResourceType)
    
}





extension PROPrescriberResourceProtocol where MeasurementResourceType : DomainResource, PrescribingResourceType : DomainResource {
    
    
    public func fetchObservations(callback: ((Bool) -> Void)? = nil) {
        guard let p = smartManager.patient, let pr = prescribingResource else {
            return
        }
        var ss  = self
        
        let param = ["patient" : p.id!.string,
                     "based-on": pr.id!.string]
        
        let  search = MeasurementResourceType.search(param)
        search.perform(smartManager.client.server, callback: {  (bundle, ferror) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is MeasurementResourceType}.map { $0.resource as! MeasurementResourceType }
                ss.measurementResources = resources
                callback?(ss.measurementResources != nil)
            }
        })
    }
}

extension PROPrescriberResourceProtocol where PrescribingResourceType : DomainResource {
    
    public static func CreateFromResource(for patient: Patient, params: [String: String]? = nil, client: SMART.Client, callback: @escaping (_ resource: [Self]?, _ error : Error?) -> Void) {
        client.ready { (error) in
            if nil != error {
                callback(nil, error)
                return
            }
            let params = ["patient" : patient.id!.string]
            let search = PrescribingResourceType.search(params)
            search.perform(client.server, callback: { (bundle, ferror) in
                if let bundle = bundle {
                    let resources = bundle.entry?.filter { $0.resource is PrescribingResourceType}.map { Self.init(pr: $0.resource as! PrescribingResourceType) }
                    callback(resources, nil)
                }
                else {
                    callback(nil, ferror)
                }
            })
        }
    }
}

public class PROMeasureBase : Equatable {
    
    public var title: String
    
    public var identifier: String
    
    required public init(title: String, identifier: String) {
        self.title = title
        self.identifier = identifier
    }
    
    public var schedule: Schedule?
    
    
    public var status : SlotStatus? {
        get {
            return schedule?.status
        }
    }
    
    public var scores : [Double]?
    
    
    
    public static func == (lhs: PROMeasureBase, rhs: PROMeasureBase) -> Bool {
        return (lhs.identifier == rhs.identifier)
    }
}
*/
