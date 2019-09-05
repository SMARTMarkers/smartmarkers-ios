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


public struct FHIRSearchParamRelationship {
    
    public let resourceType: ReportType.Type
    public let relation: [String: String]
    public init(_ type: ReportType.Type, _ relation: [String: String]) {
        self.resourceType = type
        self.relation = relation
    
    }
}


open class Reports {
    
    //TODO: SORT by Date
    weak var request: RequestProtocol?
    
    weak var instrument: InstrumentProtocol?
    
    weak var patient: Patient?
    
    open lazy var reports: [ReportType] = {
       return [ReportType]()
    }()
    
    open lazy var newBundles: [SMART.Bundle] = {
        return [SMART.Bundle]()
    }()
    
    open var resultLinks: [FHIRSearchParamRelationship]?
    
    public init(resultRelations: [FHIRSearchParamRelationship]?, _ patient: Patient?) {
        self.resultLinks = resultRelations
        self.patient = patient
    }
    
    open func add(resource: ReportType) {
        reports.append(resource)
    }
    
    
    open func add(resources: [ReportType]) {
        reports.append(contentsOf: resources)
    }
    
    
    
    
    open func fetch(server: Server, searchParams: [String:String]?, callback: @escaping ((_ _results: [ReportType]?, _ error: Error?) -> Void)) {
        
        let group = DispatchGroup()
        for type in resultLinks! {
            let search = type.resourceType.search(type.relation as Any)
            search.pageCount = 100
            group.enter()
            search.perform(server) { [unowned self]  (bundle, error) in
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
    
    open func add(_ bundle: SMART.Bundle) {
        newBundles.append(bundle)
    }
    
    
    open func submitBundle(_ bundle: SMART.Bundle,  server: Server, consent: Bool, patient: Patient, request: RequestProtocol?, callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        
        var _bundle = bundle
        
        Reports.Tag(&_bundle, with: patient, request: request)
        
        let handler = FHIRJSONRequestHandler(.POST, resource: _bundle)
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
                callback(false, SMError.reportSubmissionToServerError)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    
    public static func Tag(_ bundle: inout SMART.Bundle, with patient: Patient?, request: RequestProtocol?) {
        
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
            }
        }
        catch {
            
            print(error)
        }
    }
    
    
}


