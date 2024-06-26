//
//  Reports.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/20/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public struct TaskReport {
    
    /// Weak reference to `taskController`
    weak var taskController: TaskController?
    
    /// Practitioner's `Request`
    weak var request: Request?
    
    /// Instrument for which the reports are fetched or generated
    weak var instrument: Instrument?
    
    /// Patient for which the reports are fetched or generated
    weak var patient: Patient?
    
    /// generated bundle
    var bundle: SMART.Bundle?
    
    /// attempted metric
    var metric: TaskAttempt
    
    /// Are the reports in bundle submitted to server?
    var isSubmitted: Bool {
        bundle?.entry?.filter({ $0.resource?.id == nil }).count == 0
    }
    
    var reports: [Report]? {
        bundle?.entry?.compactMap ({ $0.resource as? Report })
    }
    
}

/**
 Reports Collection Class
 
 Instances of this class are mainly responsible for fetching historical `Report` conformant FHIR resources and submit newly created resources.
 */
open class Reports {
    
    static let calendar = Calendar.current
    
    /// Weak reference to `taskController`
    weak var taskController: TaskController?
    
    /// Practitioner's `Request`
    weak var request: Request?
    
    /// Instrument for which the reports are fetched or generated
    weak var instrument: Instrument?
    
    /// Patient for which the reports are fetched or generated
    weak var patient: Patient?
    
    /// Collection of `Report`s fetched from the FHIR `Server`
    private lazy var _reports: [Report] = {
        [Report]()
    }()
    
    /// Public reference to _reports
    open var reports: [Report] {
        _reports
    }
    
    /// Collection of `InstrumentResult`; Yet to be submitted
    private lazy var _submissionQueue: [InstrumentResult] = {
        [InstrumentResult]()
    }()
    
    /// Public reference to queue
//    open var submissionQueue: [InstrumentResult] {
//        return _submissionQueue
//    }
    
    open var recent: InstrumentResult? {
        _submissionQueue.last
    }
    
    public init(for task: TaskController) {
        self.taskController = task
    }
    
    /// Boolean to determine if there are reports generated Today
    public func hasReportsForToday() -> Bool {
        for report in reports {
            if let date = report.rp_date, Reports.calendar.isDateInToday(date) {
                return true
            }
        }
        return false
    }
    
    /// Boolean to determine if there are unsubmitted FHIR resources
    public var hasReportsToSubmit: Bool {
        !_submissionQueue.isEmpty
    }
    
    public func reportsToSubmit() -> [InstrumentResult]? {
        _submissionQueue
    }
    
    
    
    /**
     Designated Initializer.
     
     - parameter instrument:    The `Instrument` the receiver should fetch or submit the reports for
     - parameter for:           The `Patient` for which the reports are fetched or submitted
     - parameter request:       The `Request` for which the reports are fetched or generated
     */
    public init(_ instrument: Instrument, for patient: Patient?, request: Request?) {
        
        self.instrument = instrument
        self.patient = patient
        self.request = request
    }
    
    /// `Report conformant FHIR Resource to the receiver
    private func add(_ resource: Report) {
        _reports.append(resource)
    }
    
    /// `Report` conformant FHIR Resources added to the receiver
    private func add(_ resources: [Report]) {
        _reports.append(contentsOf: resources)
    }
    
    /// Returns `InstrumentResult` generated from a specific user task session (taskId) from the queue
    open func instrumentResult(for taskId: String) -> InstrumentResult? {
        
        return _submissionQueue.filter({ (instrumentResult) -> Bool in
            return instrumentResult.taskId == taskId
        }).first
    }
    
    /**
     Fetch historical reports for a given patient and instrument
     */
    open func fetch(for patient: Patient?, server: Server, searchParams: [String:String]?, callback: @escaping ((_ _results: [Report]?, _ error: Error?) -> Void)) {
        
        guard let resultParams = (instrument ?? taskController?.instrument)?.sm_reportSearchOptions else {
            
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
            return
        }
        
        let group = DispatchGroup()
        var errors = [Error]()
        
        for param in resultParams {
            var searchParam = param.relation
            if let pt = patient {
                searchParam["subject"] = "Patient/\(pt.id!.string)"
            }
            
            let search = param.resourceType.search(searchParam as Any)
            search.pageCount = 100
            group.enter()
            search.perform(server) { (bundle, error) in
                if let bundle = bundle, let entries = bundle.entry {
                    if entries.count > 0 {
                        let results = entries.map { $0.resource as! Report }
                        self.add(results)
                    }
                }
                if let error = error {
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            callback(self.reports, (errors.count > 0) ? SMError.reportsFetchFinishedWithErrors(description: errors.description) : nil)
        }
    }
    
   /// Add InstrumentResult to the results queue
    open func enqueueBundle(_ instrumentResult: InstrumentResult) {
        _submissionQueue.append(instrumentResult)
    }
    /// Enqueue newly created `SMART.Bundle` into the receiver's queue; prepared for submission to `FHIR Server`
    @discardableResult
    open func enqueueSubmission(_ bundle: SMART.Bundle,  taskId: String, metric: TaskAttempt, requestId: String? = nil) -> InstrumentResult  {
        let gr = InstrumentResult(taskId: taskId, bundle: bundle, metric: metric, requestId: requestId)
        _submissionQueue.append(gr)
        return gr
    }
    
    
    /**
     Attempts to submit the `reportBundles` in the receiver's queue (`submissionQueue`)
     
     Note: `instrumentResult.canSubmit` flag must be `true` for submission; else will be discarded.
     
     - parameter server:    `FHIR Server` to submit too
     - parameter patient:   `SMART.Patient` resource
     - parameter request:   `Request` resource (optional)
     - parameter callback:  Callback indicating success or fail with errors when attempted submission
     */
    open func submit(to server: Server, patient: Patient, request: Request?, callback: @escaping ((_ success: Bool, _ error: [Error]?) -> Void)) {
        
        guard !_submissionQueue.isEmpty else {
            callback(true, nil)
            return
        }
        
        
        let group  = DispatchGroup()
        var errors = [Error]()
        
        for submission in _submissionQueue {
            
            // TODO: Send the taskMetric?
            if submission.bundle == nil {
                continue
            }
            
          
            
            try? Reports.Tag(&submission.bundle!, with: patient, request: request)
            group.enter()
            submit(bundle: submission.bundle!, server: server) { (success, error) in
                if let error = error {
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            
            // Remove all submitted bundles from the which were submitted or discarded
            self._submissionQueue.removeAll(where: { (submission) -> Bool in
                (submission.status == .submitted || submission.status == .discarded)
            })
            callback(errors.isEmpty, errors)
        }
        
        
    }
    
    open func submit(to server: Server, patient: Patient, callback: @escaping ((_ success: Bool, _ error: [Error]?) -> Void)) {
        submit(to: server, patient: patient, request: taskController?.request ?? request, callback: callback)
    }
    
    /**
     Static method for "tagging" the generated `Bundle` with the patient and request if available.
     
     Resources contained in the `Bundle` are checked for known resource types and tagged with Patient and Requests's `Reference`
     Supported FHIR Resources: `QuestionnaireResponse`, `Observation`, `Binary`, `Media`, `Immunization`, `AllergyIntolerance`, `Condition`, `MedicationRequest`, `Procedure`, `DocumentRefereence`
     
     - parameter bundle:    Generated output in `SMART.Bundle` to tag
     - parameter with:      The `Patient` to associate the bundle resources with
     - parameter request:   The `Request` to associate the bundle resources with
     */
	public static func Tag(_ bundle: inout SMART.Bundle, with patient: Patient?, request: Request?) throws {
        
        do {
			
			
            let patientReference = try patient?.asRelativeReference()
            let requestReference = try (request as? ServiceRequest)?.asRelativeReference()
            
            for entry in bundle.entry ?? [] {
				
                //QuestionnaireResponse
                if let answers = entry.resource as? QuestionnaireResponse {
                    answers.subject = patientReference
                    if let r = requestReference {
                        var basedOns = answers.basedOn ?? [Reference]()
                        basedOns.append(r)
                        answers.basedOn = basedOns
                    }
                }
                
                //Observation
                if let observation = entry.resource as? Observation {
                    observation.subject = patientReference
                    if let r = requestReference {
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
                    if let reqReference = requestReference {
                        media.basedOn = [reqReference]
                    }
                }
                
                // Immunization
                if let immunization = entry.resource as? Immunization {
                    immunization.patient = patientReference
                }
                
                // AllergyIntolerance
                if let allergyIntolerance = entry.resource as? AllergyIntolerance {
                    allergyIntolerance.patient = patientReference
                }
                
                // Condition
                if let condition = entry.resource as? Condition {
                    condition.subject = patientReference
                }
                
                // MedicationRequest
                if let medicationRequest = entry.resource as? MedicationRequest {
                    medicationRequest.subject = patientReference
                }
				
				// MedicationStatement
				if let medicationStatement = entry.resource as? MedicationStatement {
					medicationStatement.subject = patientReference
				}
                
                // Procedure
                if let procedure = entry.resource as? Procedure {
                    procedure.subject = patientReference
                }
                
                // DocumentReference
                if let documentReference = entry.resource as? DocumentReference {
                    documentReference.subject = patientReference
                }
                
            }
        }
        catch {
            throw error
        }
    }
	
	public static func Tag(_ resources: inout [Resource], with patient: Patient?, request: Request?) throws {
		
		let patientReference = try patient?.asRelativeReference()
		let requestReference = try request?.asRelativeReference()
		
		for resource in resources {
			//QuestionnaireResponse
			if let answers = resource as? QuestionnaireResponse {
				answers.subject = patientReference
				if let r = requestReference {
					var basedOns = answers.basedOn ?? [Reference]()
					basedOns.append(r)
					answers.basedOn = basedOns
				}
			}
			
			//Observation
			if let observation = resource as? Observation {
				observation.subject = patientReference
				if let r = requestReference {
					var basedOns = observation.basedOn ?? [Reference]()
					basedOns.append(r)
					observation.basedOn = basedOns
				}
			}
			
			//Binary
			if let binary = resource as? Binary {
				binary.securityContext = patientReference
			}
			
			//Media
			if let media = resource as? Media {
				media.subject = patientReference
				if let reqReference = requestReference {
					media.basedOn = [reqReference]
				}
			}
			
			// Immunization
			if let immunization = resource as? Immunization {
				immunization.patient = patientReference
			}
			
			// AllergyIntolerance
			if let allergyIntolerance = resource as? AllergyIntolerance {
				allergyIntolerance.patient = patientReference
			}
			
			// Condition
			if let condition = resource as? Condition {
				condition.subject = patientReference
			}
			
			// MedicationRequest
			if let medicationRequest = resource as? MedicationRequest {
				medicationRequest.subject = patientReference
			}
			
			// MedicationStatement
			if let medicationStatement = resource as? MedicationStatement {
				medicationStatement.subject = patientReference
			}
			
			
			// Procedure
			if let procedure = resource as? Procedure {
				procedure.subject = patientReference
			}
			
			// DocumentReference
			if let documentReference = resource as? DocumentReference {
				documentReference.subject = patientReference
			}
		}
		
	}

    
    
    /**
     Submission method
     
     Submits FHIR resources in the receiver's InstrumentResult (`SMART.Bundle`) to the FHIR server
     FHIR Bundle **Transaction** method is used.
     
     - parameter bundle: `SMART.Bundle` containing FHIR resources
     - parameter server:    FHIR `Server` to write resources
     - parameter callback:  The callback to call when operation completed with a success (Bool)
     */
    open func submit(bundle: SMART.Bundle, server: Server, callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        let handler = FHIRJSONRequestHandler(.POST, resource: bundle)
        let headers = FHIRRequestHeaders([.prefer: "return=representation"])
        handler.add(headers: headers)
        let semaphore = DispatchSemaphore(value: 0)
        server.performRequest(against: "//", handler: handler) { [weak self] (response) in
            
            if let response = response as? FHIRServerJSONResponse,
                let json = response.json,
                let responseBundle = try? SMART.Bundle(json: json) {
                if let results = responseBundle.entry?.filter({ $0.resource is Report}).map({ $0.resource as! Report }) {
                    self?.add(results)
                    callback(true, nil)
                }
                else {
                    callback(false, SMError.reportUnknownFHIRReport)
                }
            }
            else {
                callback(false, SMError.reportSubmissionToServerError(serverError: response.error ?? SMError.undefined(description: "unknown error when submitting reports")))
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    
}
