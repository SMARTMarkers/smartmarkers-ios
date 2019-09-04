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


public struct PROFhirLinkRelationship {
    
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
    
    open var types: [ReportType.Type]?
    
    open var resultLinks: [PROFhirLinkRelationship]?
    
    public init(resultRelations: [PROFhirLinkRelationship]?, _ patient: Patient?) {
        self.resultLinks = resultRelations
        self.patient = patient
    }
    
    open func add(resource: ReportType) {
        reports.append(resource)
    }
    
    
    open func add(resources: [ReportType]) {
        reports.append(contentsOf: resources)
    }
    
    
    
    open func fetchResults(server: Server, searchParams: [String:String]?, callback: @escaping ((_ _results: [ReportType]?, _ error: Error?) -> Void)) {
        
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
    
    open func showSubmit(with consent: Bool, callback: @escaping ((_ success: Bool, _ error: Bool) -> Void)) {
        
    }
    
    
}


