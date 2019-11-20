//
//  AdaptiveServer.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 12/18/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class AdaptiveServer : SMART.Server {
    
    private var client_id : String?
    
    private var client_secret: String?
    
    public required init(baseURL base: URL, auth: [String : Any]?) {
        if let c_id = auth?["client_id"] as? String, let c_secret = auth?["client_secret"] as? String  {
            self.client_secret = c_secret
            self.client_id = c_id
        }
 
        super.init(baseURL: base)
    }
    
    open override func handlerForRequest(withMethod method: FHIRRequestMethod, resource: Resource?) -> FHIRRequestHandler? {
        let handler = FHIRJSONRequestHandler(method, resource: resource)
        handler.options.insert(.lenient)
        return handler
    }
    
    public override func configurableRequest(for url: URL) -> URLRequest {
        var request = super.configurableRequest(for: url)
        let auth    = String(format: "%@:%@", client_id!, client_secret!)
        let data    = auth.data(using: .utf8)!
        let basic   = data.base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.setValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        return request
    }

    
    public func discover(callback : @escaping (([Questionnaire]?, Error?) -> Void)) {
        
        Questionnaire.search(["_summary":"true"]).perform(self) { (bundle, error) in
            if let bundle = bundle {
                let questionnaires = bundle.entry?.filter { $0.resource is Questionnaire }.map { $0.resource as! Questionnaire}
                callback(questionnaires, error)
            }
            else {
                callback(nil, error)
            }
        }
    }
}


