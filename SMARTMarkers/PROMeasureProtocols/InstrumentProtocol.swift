//
//  InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


public protocol InstrumentProtocol : class {
    
    var ip_title: String { get }
    
    var ip_identifier: String { get }
    
    var ip_code: SMART.Coding? { get }
    
    var ip_version: String? { get }
    
    var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? { get }
    
    /// Protocol Func to generate ResearchKit's `ORKTaskViewController`
    func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
    /// Protocol Func to generate a FHIR `Bundle` of result resources. eg. QuestionnaireResponse, Observation
    func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle?
    
}


public extension InstrumentProtocol where Self: SMART.DomainResource {
    
    static func Instruments(from server: Server, options: [String:String]?, callback: @escaping ((_ instrumentResources: [Self]?, _ error: Error?) -> Void)) {
        let search = Self.search(options as Any)
        search.pageCount = 100
        search.perform(server) { (bundle, error) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is Self }.map { $0.resource as! Self }
                callback(resources , nil)
            }
            else {
                callback(nil, error)
            }
        }
    }
    
}
