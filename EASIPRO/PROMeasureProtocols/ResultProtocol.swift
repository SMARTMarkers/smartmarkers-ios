//
//  ResultProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public typealias ResultType = DomainResource & ResultProtocol


public protocol ResultProtocol {
    
    var rp_title : String? { get }
    var rp_description: String? { get }
    var rp_date: Date { get }
    var rp_observation: String? { get }
    static func searchParam(from: [DomainResource.Type]?) -> [String : String]?
    
}


public struct PROFhirLinkRelationship {
    
    public let resourceType: ResultType.Type
    public let relation: [String: String]
    public init(_ type: ResultType.Type, _ relation: [String: String]) {
        self.resourceType = type
        self.relation = relation
    
    }
}


open class PROResults {
    
    //TODO: SORT by Date
    weak var request: RequestProtocol?
    
    weak var instrument: InstrumentProtocol?
    
    weak var patient: Patient?
    
    open var results: [ResultType]?
    
    open var types: [ResultType.Type]?
    
    open var resultLinks: [PROFhirLinkRelationship]?
    
    public init(resultRelations: [PROFhirLinkRelationship]?, _ patient: Patient?) {
        self.resultLinks = resultRelations
        self.patient = patient
    }
    
    open func add(resource: ResultType) {
        if results == nil { results = [ResultType]() }
        results?.append(resource)
    }
    
    
    open func add(resources: [ResultType]) {
        if results == nil { results = [ResultType]() }
        results?.append(contentsOf: resources)
    }
    
    
    
    open func fetchResults(server: Server, searchParams: [String:String]?, callback: @escaping ((_ _results: [ResultType]?, _ error: Error?) -> Void)) {
        
        let group = DispatchGroup()
        for type in resultLinks! {
            let search = type.resourceType.search(type.relation as Any)
            group.enter()
            search.perform(server) { [unowned self]  (bundle, error) in
                if let bundle = bundle, let entries = bundle.entry {
                    if entries.count > 0 {
                        let results = entries.map { $0.resource as! ResultType }
                        self.add(resources: results)
                    }
                }
                if let error = error {
                    print(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            callback(self.results, nil)
        }
        
    }
    
    
}



extension QuestionnaireResponse : ResultProtocol {
    
    public var rp_title: String? {
        return "Response #\(id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        if let questionnaire = questionnaire {
            return "Response For  \(questionnaire.url.lastPathComponent)"
        }
        return "QuestionnaireResponse"
    }
    
    public var rp_date: Date {
        return authored?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return nil
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
}




extension Observation : ResultProtocol {
    
    
    public var rp_title: String? {
        if let code = code?.text?.string {
            return code
        }
        
        return "Observation: #\(self.id?.string ?? "-")"
    }
    
    public var rp_description: String? {
        return "Observation [Survey]"
    }
    
    public var rp_date: Date {
        return effectiveDateTime?.nsDate ?? Date()
    }
    
    public var rp_observation: String? {
        return observationValueString()
    }
    
    public static func searchParam(from: [DomainResource.Type]?) -> [String : String]? {
        return nil
    }
    
    func observationValueString() -> String? {
        if let v = valueString?.string { return v }
        if let v = valueQuantity { return String(describing: v.value!) }
        return nil
    }
    
    
    
}
