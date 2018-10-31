//
//  EventResource.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/1/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



public protocol SearchableResourceProtocol  : FHIRResourceProtocol {

    func toRecord() -> Record
    static func searchCode(code: String?, system: String?, referencingResource: Reference?) -> [String:String]
}




public protocol ResourceFetchProtocol {
    
    var records: [Record]? { get set }
    var searchParams: [String: String]? { get set }
    func getEvents(server: Server, callback: (([Record]?, Error?) -> Void)?)

}


open class ResourceFetch<T: DomainResource & SearchableResourceProtocol> : ResourceFetchProtocol {
    
    public var searchParams: [String : String]?
    public var records : [Record]?
    public var _records : Records<T>?
    
    public var resourceType: T.Type
    
    public init(_ _type: T.Type, _ _code: String, _ _system: String) {
        resourceType = _type
        searchParams = resourceType.searchCode(code: _code, system: _system, referencingResource: nil)
    }
    public init(_ _type: T.Type, param: [String:String]?) {
        resourceType = _type
        searchParams = param
    }
    
    public func _add(_ resources: [T]) {
        _records?.add(resources)
    }

    public func add(resources: [T]) {
        
        if records == nil { records = [Record]() }
        records?.append(contentsOf: resources.map { $0.toRecord() })
    }
    
    public func getEvents(server: Server, callback: (([Record]?, Error?) -> Void)?) {

        //TODO: add `$sort` capability.
        resourceType.Get(server: server, param: searchParams) { [weak self] (resources, error) in
            if let resources = resources {
                let records = resources.map { $0.toRecord() }
                self?.records = records
                self?._records = Records(records: records)
                callback?(records, nil)
            }
            else {
                callback?(nil, nil)
            }
        }
    }

    
    
}

public struct Records<T: DomainResource & SearchableResourceProtocol>{
    
    public var records: [Record]
    
    mutating func add(_ resource: T) {
        records.append( resource.toRecord() )
    }
    
    mutating func add(_ resources: [T]) {
        records.append(contentsOf: resources.map{ $0.toRecord() })
    }
    
    subscript(index: Int) -> Record? {
        get {
            return records[index]
        }
    }
    
    
}


public struct Record {

    public let title : String
    public let description : String
    public let date: Date
    public let score: String?
    public let resource: DomainResource?
    
    public init(_title: String, _description: String, _date: Date, _score: String?, _resource: DomainResource?) {
        title = _title
        description = _description
        date = _date
        score = _score
        resource = _resource
    }

}

public class EventResource  {
    
    public var fetches: [ResourceFetchProtocol]
    
    public required init(_ definitions: [ResourceFetchProtocol]) {
        self.fetches = definitions
    }
    
    public func fetchAllEvents(server: Server, callback: @escaping ((_ success: Bool) -> Void)) {
        
        let bgthread = DispatchGroup()
        fetches.forEach {
            bgthread.enter()
            $0.getEvents(server: server, callback: { (_ , _ ) in
                bgthread.leave()
            })
        }
        bgthread.notify(queue: .global()) {
            callback(true)
        }
    }
    
}



extension Observation : SearchableResourceProtocol {
    
    public static func searchCode(code: String?, system: String?, referencingResource: Reference?) -> [String : String] {
        var dict = [String:String]()
        if let code = code, let system = system {
            dict.updateValue("\(system)|\(code)", forKey: "code")
        }
        return dict
    }
    
    
    public func toRecord() -> Record {

        
        return Record(_title: code!.text!.string, _description: "Observation", _date: effectiveDateTime!.nsDate, _score: observationValueString(), _resource: self)
        
    }
    
    
    func observationValueString() -> String? {
        if let v = valueString?.string { return v }
        if let v = valueQuantity { return String(describing: v.value!) }
        return nil
    }
    
}

extension QuestionnaireResponse : SearchableResourceProtocol {
    
    public func toRecord() -> Record {
        let date = authored?.nsDate ?? Date()
        return Record(_title: "Response", _description: "PRO Responses", _date: date, _score: nil, _resource: self)
    }
    
    public static func searchCode(code: String?, system: String?, referencingResource: Reference?) -> [String : String] {
        return ["something": "something"]
    }
    
}
