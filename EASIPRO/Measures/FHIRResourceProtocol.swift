//
//  FHIRDomainResourceProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/27/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART




public protocol FHIRResourceProtocol : class {

    var pro_identifier: String? { get }
}

extension FHIRResourceProtocol where Self : DomainResource {
    
    public var pro_identifier: String? {
        get {
            return id?.string
        }
    }
    
    
    public static func Get(server: Server, param : [String:String]?, callback: @escaping ((_ resources: [Self]?, _ error : Error?) -> Void)) {
        
        let search = Self.search(param as Any)
        search.pageCount = 100
        search.perform(server) { (bundle, error) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is Self  }.map { $0.resource as! Self }
                callback(resources , nil)
            }
            else {
                print("ERROR", error as Any)
                callback(nil, error)
            }
        }
    }


}

/*
public protocol FHIRDomainResourceClassProtocol : class  {
    
    associatedtype FHIRDomainResource : DomainResource
    
    var resource : FHIRDomainResource { get set }
    
    var title : String? { get }
    
    init(_ _resource: FHIRDomainResource)
}



extension FHIRDomainResourceClassProtocol  {
    
    public var pro_identifier : String {
        get {
            return resource.id!.string
        }
    }
    
    
    
    public static func search(client: Client, param : [String:String]?, callback: @escaping ((_ resources: [Self]?, _ error : Error?) -> Void)) {
        
        let search = FHIRDomainResource.search(param as Any)
        search.perform(client.server) { (bundle, ferror) in
            if let bundle = bundle {
                let resources = bundle.entry?.filter { $0.resource is FHIRDomainResource  }.map { Self.init($0.resource as! FHIRDomainResource) }
                callback(resources , nil)
            }
            else {
                print("ERROR", ferror as Any)
                callback(nil, ferror)
            }
        }
    }
}


*/



