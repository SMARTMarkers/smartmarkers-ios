//
//  RequestProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/1/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

/*
 
 PRO Request Protocol
 Fetches and Manages `FHIR` request resource
 
 */
public protocol RequestProtocol :  class, CustomStringConvertible {
    
    
    /// Request identifier
    var rq_identifier: String { get }
    
    /// Title Representation of the Request
    var rq_title: String? { get }
    
    /// Person requesting the PRO
    var rq_requesterName: String? { get }
    
    /// Entity requesting the PRO
    var rq_requesterEntity: String? { get }
    
    /// Date of Request
    var rq_requestDate: Date? { get }
    
    /// Primary identifying Request Code
    var rq_categoryCode: String? { get }
    
    /// Deduced Schedule
    var rq_schedule: Schedule? { get }
    
    /// Fetch Parameters
    static var rq_fetchParameters: [String: String]? { get }
    
    ///::: Should this be a Delegate Protocol?
    /// Notifies request has been updated
    func rq_updated(_ completed: Bool, callback: @escaping ((_ success: Bool) -> Void))
    
    /// Requested Instrument
    func rq_instrumentResolve(callback: @escaping ((_ instrument: InstrumentProtocol?, _ error: Error?) -> Void))
    
    /// Resolve FHIR References if needed;
    func rq_resolveReferences(callback: @escaping ((Bool) -> Void))

}

public extension RequestProtocol {
    
    var description : String {
        return "PRORequest: \(rq_identifier)"
    }
}


public extension RequestProtocol where Self: SMART.DomainResource {
    
    static func Requests(from server: Server, options: [String:String]?, callback: @escaping ((_ requestResources: [Self]?, _ error: Error?) -> Void)) {
        let search = Self.search(options as Any)
        search.pageCount = 100
        search.perform(server) { (bundle, error) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is Self }.map { $0.resource as! Self }
                let group = DispatchGroup()
                for r in resources ?? [] {
                    group.enter()
                    r.rq_resolveReferences(callback: { (completed ) in
                        group.leave()
                    })
                }
                
                group.notify(queue: .global(qos: .userInteractive), execute: {
                    callback(resources, nil)
                })

            }
            else {
                callback(nil, error)
            }
        }
    }
    
    var asFHIR : DomainResource? {
        return self 
    }
    
    
}