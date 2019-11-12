//
//  ResultProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public typealias ReportType = DomainResource & ReportProtocol


public protocol ReportProtocol {
    
    var rp_resourceType: String { get }
    var rp_identifier: String? { get }
    var rp_title : String? { get }
    var rp_description: String? { get }
    var rp_date: Date { get }
    var rp_observation: String? { get }
    var rp_submitted: Bool { get }
    static func searchParam(from: [DomainResource.Type]?) -> [String : String]?
    
}

public extension ReportProtocol where Self: ReportType {
    
    var rp_submitted: Bool {
        return (id != nil)
    }
}

public extension ReportProtocol where Self: DomainResource {
    
    var rp_resourceType: String {
        return sm_resourceType()
    }
}


public struct FHIRSearchParamRelationship {
    
    public let resourceType: ReportType.Type
    public let relation: [String: String]
    public init(_ type: ReportType.Type, _ relation: [String: String]) {
        self.resourceType = type
        self.relation = relation
    
    }
}

public class SubmissionBundle {
    
    public enum SubmissionStatus: String, CustomStringConvertible {
        
        public var description: String {
            get {
                switch self {
                case .readyToSubmit:
                    return "Ready"
                case .submitted:
                    return "Submitted"
                case .failedToSubmit:
                    return "Failed to Submit"
                case .discarded:
                    return "Discarded"
                }
            }
        }
        
        case readyToSubmit
        case submitted
        case failedToSubmit
        case discarded
    }
    
    public final let taskId: String
    public final let bundle: SMART.Bundle
    public final let requestId: String?
    public internal(set) var shouldSubmit: Bool = false
    public internal(set) var status: SubmissionStatus
    
    init(taskId: String, bundle: SMART.Bundle, requestId: String? = nil) {
        self.taskId = taskId
        self.bundle = bundle
        self.requestId = requestId
        self.status = .readyToSubmit
    }
    
    
}


open class Reports {
    
    //TODO: SORT by Date
    weak var request: Request?
    
    weak final var instrument: Instrument!
    
    weak var patient: Patient?
    
    open lazy var reports: [ReportType] = {
       return [ReportType]()
    }()
    
    open lazy var submissionBundle: [SubmissionBundle] = {
        return [SubmissionBundle]()
    }()
    
    public init(_ instrument: Instrument, for patient: Patient?, request: Request?) {
        
        self.instrument = instrument
        self.patient = patient
        self.request = request
    }
    
    open func add(resource: ReportType) {
        reports.append(resource)
    }
    
    
    open func add(resources: [ReportType]) {
        reports.append(contentsOf: resources)
    }
    
    
    open func submissionBundle(for taskId: String) -> SubmissionBundle? {
        
        return submissionBundle.filter({ (submissionBundle) -> Bool in
            return submissionBundle.taskId == taskId
        }).first
    }
    
    open func fetch(for patient: Patient?, server: Server, searchParams: [String:String]?, callback: @escaping ((_ _results: [ReportType]?, _ error: Error?) -> Void)) {
     
        guard let resultParams = instrument.sm_resultingFhirResourceType else {
            callback(nil, SMError.reportUnknownFHIRReportType)
            return
        }
        
        
        let group = DispatchGroup()
        for param in resultParams {            
            var searchParam = param.relation
            if let pt = patient {
                searchParam["subject"] = "Patient/\(pt.id!.string)"
            }
            //Todo: Remove
            print(searchParam)

            let search = param.resourceType.search(searchParam as Any)
            search.pageCount = 100
            group.enter()
            search.perform(server) { (bundle, error) in
                if let bundle = bundle, let entries = bundle.entry {
                    if entries.count > 0 {
                        let results = entries.map { $0.resource as! ReportType }
                        self.add(resources: results)
                    }
                }
                if let error = error {
                    print(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            callback(self.reports, nil)
        }
    }
    
    @discardableResult
    open func addNewReports(_ bundle: SMART.Bundle,  taskId: String) -> SubmissionBundle  {
        let gr = SubmissionBundle(taskId: taskId, bundle: bundle, requestId: nil)
        submissionBundle.append(gr)
        return gr
    }
    
    
    /// Prepare for Submission to `Server`.
    open func submit(to server: Server, consent: Bool, patient: Patient, request: Request?, callback: @escaping ((_ success: Bool, _ error: [Error]?) -> Void)) {
        
        guard !submissionBundle.isEmpty else {
            callback(true, nil)
            return
        }
        
    
        let group  = DispatchGroup()
        var errors = [Error]()
        
        for gr in submissionBundle {
            
//            if !gr.shouldSubmit {
//                gr.status = .discarded
//                continue
//            }
            
            var _bundle = gr.bundle
            Reports.Tag(&_bundle, with: patient, request: request)
            group.enter()
            submit(bundle: _bundle, server: server) { (success, error) in
                if let error = error {
                    errors.append(error)
                }
                gr.status = (success) ? .submitted : .failedToSubmit
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            callback(errors.isEmpty, errors)
        }
        
        
    }
    
    
    public static func Tag(_ bundle: inout SMART.Bundle, with patient: Patient?, request: Request?) {
        
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
            
            print(error)
        }
    }
    
    
    
    open func submit(bundle: SMART.Bundle, server: Server, callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        let handler = FHIRJSONRequestHandler(.POST, resource: bundle)
        let headers = FHIRRequestHeaders([.prefer: "return=representation"])
        handler.add(headers: headers)
        let semaphore = DispatchSemaphore(value: 0)
        server.performRequest(against: "//", handler: handler) { [weak self] (response) in
            
            if let response = response as? FHIRServerJSONResponse,
                let json = response.json,
                let responseBundle = try? SMART.Bundle(json: json) {
                if let results = responseBundle.entry?.filter({ $0.resource is ReportType}).map({ $0.resource as! ReportType }) {
                    self?.add(resources: results)
                    callback(true, nil)
                }
                else {
                    callback(false, SMError.reportUnknownFHIRReportType)
                }
            }
            else {
                callback(false, SMError.reportSubmissionToServerError(serverError: response.error ?? SMError.undefined))
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    
}




extension SMART.Bundle {
    
    func sm_ContentSummary() -> String? {
        
        let content = entry?.reduce(into: String(), { (bundleString, entry) in
            let report = entry.resource as? ReportType
            bundleString += report?.sm_resourceType() ?? "Type: \(entry.resource?.sm_resourceType() ?? "-")"
            bundleString += ": " + (report?.rp_date.shortDate ?? "-")
            bundleString += "\n"
        })
        
        return content == nil ? nil : String(content!.dropLast())
    }
    
    func sm_resourceCount() -> Int {
        return entry?.count ?? 0
    }
}
