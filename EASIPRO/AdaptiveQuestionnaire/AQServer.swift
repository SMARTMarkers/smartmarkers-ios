//
//  AQServer.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 12/18/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class PROMISServer: AQServer {
    
    public convenience init(base: URL, clientid: String, clientsecret: String) {
        let settings = [
            "client_id" : clientid,
            "client_secret" : clientsecret
        ]
        self.init(baseURL: base, auth: settings)
    }
}

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
        let authType = "client_credentials"
        let settings = [
            "client_id" : usr,
            "client_secret" : pass
        ]
        
    
        
        let server = AQServer(baseURL: URL(string: base)!, auth: settings)
        Questionnaire.read("96FE494D-F176-4EFB-A473-2AB406610626", server: server, callback: { (questionnaire, error) in
            
            if let r4 = questionnaire as? Questionnaire {
                r4.item = nil
                let qr = try! QuestionnaireResponse.sm_AdaptiveQuestionnaireBody(contained: r4)
                r4.next_q(server: server, questionnaireResponse: qr) { (resource, error) in
                    do {
                        if let resource = resource as? QuestionnaireResponse {
                            if let questionnaire = resource.contained?.first as? Questionnaire {
                                questionnaire.status = PublicationStatus.active
                                print(questionnaire.item?.first?.item?[1].answerOption)
                            }
                        }
                    }
                    catch {
                        print(error)
                    }
                }
            }
        })
        
        
        
    }
    
    public class func test2(_ vc : UIViewController) {
        
        let base = "https://mss.fsm.northwestern.edu/AC_API/2018-10/"
        let usr  = "2F984419-5008-4E42-8210-68592B418233"
        let pass = "21A673E8-9498-4DC2-AAB6-07395029A778"
        let authType = "client_credentials"
        let settings = [
            "client_id" : usr,
            "client_secret" : pass
        ]
        
        let server = AQServer(baseURL: URL(string: base)!, auth: settings)

        Questionnaire.read("96FE494D-F176-4EFB-A473-2AB406610626", server: server, callback: { (questionnaire, error) in
            
            if let r4 = questionnaire as? Questionnaire {
                
                
                
                r4.ip_taskController(for: PROMeasure(), callback: { (taskViewController, error) in

                    if let tvc = taskViewController {
                        vc.present(tvc, animated: true, completion: nil)
                    }
                })
            }
            
            
        })
        
        
        
        
        
    }
}
