//
//  PROMeasure.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/27/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

/**
Instrument resolving delegate protocol

Optional instrument resolving delegate for `TaskController`. Delegates can construct a custom `Instrument` for a given `TaskController`.  
*/
public protocol InstrumentResolver: class {
   
    /// Resolve instrument based on code and identifier
    func resolveInstrument(for code:[Coding], identifier:[Identifier], callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void))
    
    /// Resolve instrument from a Request type
    func resolveInstrument(from request: any Request, callback: @escaping ((_ instrument: Instrument?, _ error :Error?) -> Void))
    /// Called when trying to resolve the `Instrument` referenced in `Request` from the `TaskController`
    func resolveInstrument(in controller: TaskController, callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void))
    
}

/**
TaskAttempt captures start and end times with a completion state of a task
*/
public struct TaskAttempt {
	
	public enum TaskAttemptState: String {
		case discarded, failed, completedWithSuccess, completedWithoutSuccess, completed
	}
	
    public let taskId: String
	public let startTime: Date
	public let endTime: Date?
	public let state: TaskAttemptState
	
    public init(_ taskId: String, _ startTime: Date, _ endTime: Date?, _ state: TaskAttemptState) {
		self.startTime = startTime
		self.endTime = endTime
		self.state = state
        self.taskId = taskId
	}
	
	public init(serialized: [String: Any]) throws {

		guard let startTime_str = serialized["startTime"] as? String,
			  let start_dateTime = DateTime(string: startTime_str)?.nsDate,
			  let state_str 	= serialized["state"] as? String,
              let task_id     = serialized["task_id"] as? String,
			  let state			= TaskAttemptState(rawValue: state_str) else {
			throw SMError.undefined(description: "Invalid format of JSON for TaskAttempt")
		}
		
		self.startTime = start_dateTime
		self.state = state
        self.taskId = task_id
		if let endTime_str = serialized["endTime"] as? String {
			self.endTime = DateTime(string: endTime_str)?.nsDate
		}
		else {
			self.endTime = nil
		}
	}
	
	public func serialize() -> [String: Any] {
		var errors = [FHIRValidationError]()
		var json = [
			"startTime"	: startTime.fhir_asDateTime().asJSON(errors: &errors),
			"state"		: state.rawValue,
            "task_id"   : taskId
		]
		
		if let endtime_str = endTime?.fhir_asDateTime().asJSON(errors: &errors) {
			json["endTime"] = endtime_str
		}
		
		return json
	}
    

}

public extension TaskAttempt {
    
    func inFHIR(participant: (any Participant)?) -> SMART.Observation {
        
        let observation = Observation()
        observation.status = .final
        let observation_cc = CodeableConcept()
        let observation_coding = Coding()
        observation_cc.text = "Task Attempt Metrics"
        observation_coding.code = "taskattemptv3".fhir_string
        observation_coding.display = "Task Attempt Metrics".fhir_string
        observation_coding.system = FHIRURL(TaskAttemptSystem)
        observation_cc.coding = [observation_coding]
        observation.code = observation_cc
        if let participant {
            observation.subject = try? participant.fhirPatient.asRelativeReference()
        }
        
        let cc_period = CodeableConcept()
        let coding_period = Coding()
        coding_period.code = "task-period".fhir_string
        coding_period.display = "Task Period".fhir_string
        coding_period.system = FHIRURL(TaskAttemptSystem)
        cc_period.coding = [coding_period]
        let period = Period()
        period.start = startTime.fhir_asDateTime()
        period.end = endTime?.fhir_asDateTime()
        let component1 = ObservationComponent(code: cc_period)
        component1.valuePeriod = period

        let cc_result = CodeableConcept()
        let coding_result_status = Coding()
        coding_result_status.code = "task-result-status".fhir_string
        coding_result_status.display = "Task Result Status".fhir_string
        coding_result_status.system = FHIRURL(TaskAttemptSystem)
        cc_result.coding = [coding_result_status]
        let component2 = ObservationComponent(code: cc_result)
        component2.valueString = state.rawValue.fhir_string
        
        let cc_instrument = CodeableConcept()
        let coding_instrument_identifier = Coding()
        coding_instrument_identifier.code = "task-identifier".fhir_string
        coding_instrument_identifier.display = "Task Identifier".fhir_string
        coding_instrument_identifier.system = FHIRURL(TaskAttemptSystem)
        cc_instrument.coding = [coding_instrument_identifier]
        let component3 = ObservationComponent(code: cc_instrument)
        component3.valueString = self.taskId.fhir_string
        
        observation.component = [component1, component2, component3]
        return observation
       
    }
}

/** 
TaskController is the manager class ffor "request--> instrument --> report"

Each controller class can read a FHIR `Request` resource, resolve the embedded reference to its `Instrument` and fetch historical `Reports` from the `Server. Through the `Instrument` protocol, it also manages `ResearchKit` based task controllers for FHIR `Questionnaire`, `AdaptiveQuestionnaire`, active tasks, web fetches and other digital data
*/
open class TaskController: NSObject {
    
    public typealias TaskControllerCompletionCallback = (( _ attempt: TaskAttempt, _ instrumentResult: InstrumentResult?, _ error: Error?) -> Void)
    
    /// `Request` protocol conformant FHIR resource. If present, instrument is resolved from the request. See `Request.swift`
    public var request: Request?
   
    /// PGHD Instrument 
    public var instrument: Instrument?
   
    /// `Reports` holds all historial FHIR resources and the newly generated FHIR `Bundle(s)` after a user session. See `Reports.swift`
    public internal(set) final lazy var reports: Reports? = {
        return Reports(for: self)
    }()
   
    /// Optional: External resolver for the instrument. 
    public weak var instrumentResolver: InstrumentResolver?
   
    /// Callback; called when a PGHD user task-session is completed
	public var onTaskCompletion: TaskControllerCompletionCallback?
   
    /// Schedule referenced from the receiver's request
    public lazy var schedule: TaskSchedule? = {
        return request?.rq_schedule
    }()
    
    /// Schedule referenced from the receiver's request
    public var canBegin: Bool {
        return (schedule?.status == .Due || schedule?.status == .Overdue)
    }
	
	/// Instrument Presenter Options
	public var presenterOptions: InstrumentPresenterOptions?
	
	/// TaskAttemptedState
	public internal(set) lazy var attempts: [TaskAttempt] = {
		[TaskAttempt]()
	}()
    
    /// Last Attempt
    public var lastAttempt: TaskAttempt? {
        attempts.first
    }
    
    /// last attempt
//    public var currentAttempt: TaskAttempt?
   
    /**
    Initializer
    
    - parameter instrument: `Instrument` conformant class. Check `InstrumentFactory.swift` for a list of supported types out of the box.
    */
    convenience public init(instrument: Instrument) {
        self.init()
        self.instrument = instrument
    }
   
    /**
    Initializer

    - parameter request: `Request` conformant FHIR resource. 
    */
    convenience public init(_ _request: Request) {
        
        self.init()
        self.request = _request
    }

    /**
    Creates and holds `ResearchKit` based `ORKTaskViewController`. Depends on the resolved `Instrument` to pass on its task

    - parameter callback: Callback called after attempting to create a view controller for task session. 
    */
	public func prepareSession(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        guard let instrument = self.instrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        
		instrument.sm_taskController(config: presenterOptions) { (taskViewController, error) in
            taskViewController?.delegate = self
//            self.currentAttempt = nil
            callback(taskViewController, error)
        }
    }
   

    /**
    Method for the receiver to resolve instrument embedded in the receiver's request or rely on an external delegate

    - parameter callback: Called when attempt to resolve is complete. Returns `SMError` when instrument is missing
    */
    public func instrument(callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void)) {
        
        if let instr = self.instrument {
            callback(instr, nil)
            return
        }
        
        
        // No instrument, check if resolver can give us
        if let resolver = instrumentResolver {
            
            resolver.resolveInstrument(in: self) { [weak self] (instrument, error) in
                if let instr = instrument {
                    callback(instr, nil)
                }
                else {
                    self?.request?.rq_resolveInstrument(callback: callback)
                }
            }
        }
        
        else {
            request?.rq_resolveInstrument(callback: callback)
        }


    }
   
    /// Method to update status and the request if necessary
    public func updateSchedule(_ _reports: [Report]?) {

        guard let rpts = self.reports?.reports ?? _reports else { return }
        schedule?.update(with: rpts.compactMap { $0.rp_date })

    }
    
    // MARK: – Fetch Requests
   
    /**
    Constructor class method for fetching and creating TaskController objects from the FHIR server.

    Creates an array of TaskController fetched from the FHIR server. Also resolves instrument and fetches historical reports specific to the request and instrument.

    - parameter requestType:        FHIR `Request` conformant resource type to fetch
    - parameter for:                FHIR `Patient` resource to which the requests were dispatched
    - parameter server:             FHIR `Server` to query for the requests
    - parameter instrumentResolver: Optional, delegate to assign an external class to resolve instrument from the request
    - parameter options:            Optional, search parameter options for request FHIR resources
    - parameter callback:           An array of TaskController objects
    */
    public class func Requests<T: Request>(requestType: T.Type, for patient: Patient, server: Server, instrumentResolver: InstrumentResolver?, options: [String: String]? = nil, callback: @escaping ([TaskController]?, Error?) -> Void) {
        
        T.PGHDRequests(from: server, for: patient, options: options) { (requests, error) in
            if let requests = requests {
                let controllers = requests.map({ (request) -> TaskController in
                    let controller = TaskController(request)
                    controller.instrumentResolver = instrumentResolver
                    return controller
                })
                
                let group = DispatchGroup()
                for i in 0..<controllers.count {
                    let controller = controllers[i]

                    group.enter()
                    controller.instrument(callback: { (instr, error) in
                        controller.instrument = instr
                        group.leave()
                    })
                    
                    
                    group.enter()
                    controller.reports(for: patient, server: server, callback: { (_, _) in
                        controller.updateSchedule(nil)
                        group.leave()
                    })
                }

                group.notify(queue: DispatchQueue.global(qos: .background)) {
                    callback(controllers, nil)
                }

            }
            else {
                callback(nil, error)
            }
        }
    }
    
    // MARK: Report Collection
   
    /**
    Fetches historical reports (FHIR resources) based on the receiver's instrument and request

    - parameter for:        FHIR `Patient` resource
    - parameter server:     FHIR `Server` to query for the reports
    - parameter callback:   Callback with a Boolean to indicate fetch success or failure
    */
    public func reports(for patient: Patient, server: Server, callback : ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let reports = reports else {
            callback?(false, SMError.promeasureFetchLinkedResources)
            return
        }
        
        
        reports.fetch(for: patient, server: server, searchParams: nil) { (results, error) in
            callback?(results != nil, error)
        }
    }
}

// MARK: - Practitioner Requesting PGHD

public extension TaskController  {
    
    /**
     Creates and dispatches a FHIR `Request` to the FHIR Server
     
     Relies on `Request`-protocol conformant classes to configure the FHIR resource
     
     - parameter of:        FHIR Request Resource Type. Default is R4 `ServiceRequest`. Needs to conform to `Request`
     - parameter on:        FHIR `Server` for the receiver to create the resource on
     - parameter for:       `Practitioner` making the request
     - parameter schedule:  Associated repeating schedule if any (Optional)
    */
    func createRequest(of fhirType: Request.Type? = nil, on server: Server, for patient: Patient, from practitioner: Practitioner?, schedule: TaskSchedule? = nil, callback: @escaping ((_ request: Request?, _ error: Error?) -> Void)) {
        
        guard let instr = instrument else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        if request != nil {
            callback(nil, nil)
        }
        do {
            let resource = fhirType?.rq_create() ?? ServiceRequest.init()
            try resource.rq_configureNew(for: instr, schedule: schedule, patient: patient, practitioner: practitioner)
            resource.createAndReturn(server, callback: {  (error) in
                if let error = error{
                    callback(nil, error)
                }
                self.request = resource
                callback(resource, nil)
            })
        }
        catch {
            callback(nil, error)
        }
    }
}

/// Serialization for locally saving task
public extension TaskController {
		
	// Todo: Serialize FHIR resources also
	/// Serialize Attempts
	func serialize() throws -> [String: Any] {
		
        guard let instrument_identifier = instrument?.sm_code?.sm_searchableToken() else {
            throw SMError.undefined(description: "Unable to serialize; No instrument.code found")
        }
        
		let jsonAttempts = attempts.map({ $0.serialize() })
        let json = ["instrument": instrument_identifier, "attempts": jsonAttempts] as [String : Any]
        return json
	}
	
	/// Create attempts from Serialized
	func populate(from serialized: [String: Any]) throws {
		
        guard let instrument_id = serialized["instrument"] as? String,
              instrument_id == instrument?.sm_code?.sm_searchableToken() else {
                  throw SMError.undefined(description: "unable to populate, mismatched instrument identifier")
              }
        
		guard let attmps = serialized["attempts"] as? [[String: Any]] else {
			throw SMError.undefined(description: "unable to populate, invalid json format")
		}
		
		let attemp = try attmps.map ({ try TaskAttempt(serialized: $0) })
		self.attempts.append(contentsOf: attemp)
	}
}


public extension TaskController {
    
    @discardableResult
    func generateReports(from taskViewController: ORKTaskViewController, result: ORKTaskResult, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) -> InstrumentResult {
        
        
        // ***************
        // Bug :Premature firing before conclusion step
        // ***************
//        let stepIdentifier = taskViewController.currentStepViewController!.step!.identifier
//        if stepIdentifier.contains("range.of.motion") { return }
        // ***************
                
        let taskId = taskViewController.taskRunUUID.uuidString
        if reason == .discarded  {
            let attempt = recordAttempt(taskViewController, .discarded)
            let instrumentResult = InstrumentResult(taskId: taskId, bundle: nil, metric: attempt)
            reports?.enqueueBundle(instrumentResult)
            onTaskCompletion?(attempt, instrumentResult, SMError.instrumentResultBundleNotCreated)
            return instrumentResult
        }
        else if reason == .failed {
            let attempt = recordAttempt(taskViewController, .failed)
            let instrumentResult = InstrumentResult(taskId: taskId, bundle: nil, metric: attempt)
            reports?.enqueueBundle(instrumentResult)
            onTaskCompletion?(attempt, instrumentResult, SMError.instrumentResultBundleNotCreated)
            return instrumentResult
        }
        else  {
           // reason == .completed or .saved
            if let bundle = instrument?.sm_generateResponse(from: taskViewController.result, task: taskViewController.task!) {
                let attempt = recordAttempt(taskViewController, .completedWithSuccess)
                let instrumentResult = reports!.enqueueSubmission(bundle, taskId: taskViewController.taskRunUUID.uuidString, metric: attempt)
                onTaskCompletion?(attempt, instrumentResult, nil)
                return instrumentResult
            }
            else {
                let attempt = recordAttempt(taskViewController, .completedWithoutSuccess)
                let instrumentResult = InstrumentResult(taskId: taskId, bundle: nil, metric: attempt)
                reports?.enqueueBundle(instrumentResult)
                onTaskCompletion?(attempt, instrumentResult, nil)
                return instrumentResult
            }
        }
    }
}


/// Extension for PDController's ResearchKit session delegation
extension TaskController: ORKTaskViewControllerDelegate {
   
    /// Custom dismissal method. Checks if task controller is within a session controller or standalonen
    func dismiss(taskViewController: ORKTaskViewController) {
        

        if let navigationController = taskViewController.navigationController {
            //if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            //}
        }
        else {
            taskViewController.dismiss(animated: true, completion: nil)
        }
    }
   
    // MARK: Report Generation

    /// After each task session, the controller generates `InstrumentResult` holding a FHIR `Bundle` to be sent to the FHIR server. See `Instrument.sm_generateResponse(from:task:)` for more info.
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {


        generateReports(from: taskViewController,
                        result: taskViewController.result,
                        didFinishWith: reason,
                        error: error)
        
        dismiss(taskViewController: taskViewController)
    }

	
	@discardableResult
	private func recordAttempt(_ taskViewController: ORKTaskViewController, _ state: TaskAttempt.TaskAttemptState) -> TaskAttempt {
		
        guard let instrument_identifier_code = instrument?.sm_code?.sm_searchableToken() else {
             fatalError("Requires a code as an identifier")
        }

        let attempt = TaskAttempt(instrument_identifier_code,
                                  taskViewController.result.startDate,
                                  taskViewController.result.endDate,
                                  state)
//        currentAttempt = attempt
		attempts.insert(attempt, at: 0)
		return attempt
	}
}


