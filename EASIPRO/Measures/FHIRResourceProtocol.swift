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
                let resources = bundle.entry?.filter { $0.resource is Self }.map { $0.resource as! Self }
                callback(resources , nil)
            }
            else {
                callback(nil, error)
            }
        }
    }


}
