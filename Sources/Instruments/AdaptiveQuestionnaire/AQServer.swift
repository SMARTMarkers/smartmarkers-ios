//
//  AQServer.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 12/18/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class AQServer : SMART.Server {
    
    var client_id : String?
    
    var client_secret: String?
    
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
            if let error = error {
                print(error)
            }
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


public class AQClient {
    
}


public extension AQClient {
    
    class func test() {
        
        let base = "https://mss.fsm.northwestern.edu/AC_API/2018-10/"
        let usr  = "2F984419-5008-4E42-8210-68592B418233"
        let pass = "21A673E8-9498-4DC2-AAB6-07395029A778"
        let settings = [
            "client_id" : usr,
            "client_secret" : pass
        ]
        
    
        
        let server = AQServer(baseURL: URL(string: base)!, auth: settings)
       
      
        
        
    }
    
    class func test2(_ vc : UIViewController) {
        
        let base = "https://mss.fsm.northwestern.edu/AC_API/2018-10/"
        let usr  = "2F984419-5008-4E42-8210-68592B418233"
        let pass = "21A673E8-9498-4DC2-AAB6-07395029A778"
        let settings = [
            "client_id" : usr,
            "client_secret" : pass
        ]
        
        let server = AQServer(baseURL: URL(string: base)!, auth: settings)
        //96FE494D-F176-4EFB-A473-2AB406610626
        AdaptiveQuestionnaire.read("96FE494D-F176-4EFB-A473-2AB406610626", server: server, options: [.lenient]) { (questionnaire, error) in

            if let q = questionnaire {
                do {
                    var json = try q.asJSON()
                    json.removeValue(forKey: "meta")
                    let aq = try AdaptiveQuestionnaire(json: json)
                    aq.next_q2(server: server, answer: nil, forQuestionnaireItemLinkId: nil, options: [], callback: { (resource, error) in
                        print(resource)
                        print(error)
                        
                    })
                }
                catch {
                    print(error)
                }
            }
         
            
        }
       
        
        
        
        
    }
}
