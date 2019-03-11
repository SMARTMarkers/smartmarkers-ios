//
//  AQServer.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 12/18/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

public class AQFHIRJSONRequestHandler : FHIRJSONRequestHandler {
 
    override public func response(response: URLResponse?, data inData: Data?, error: Error?) -> FHIRServerResponse {
        if let res = response {
            return AQFHIRServerJSONResponse(handler: self, response: res, data: inData, error: error)
        }
        if let error = error {
            return AQFHIRServerJSONResponse(error: error, handler: self)
        }
        return AQFHIRServerJSONResponse(error: FHIRError.noResponseReceived, handler: self)    }
}

public class AQFHIRServerJSONResponse : FHIRServerJSONResponse {
    
    public override func responseResource<T>(ofType: T.Type) throws -> T where T : Resource {
        
        guard let json = json else {
            throw FHIRError.responseNoResourceReceived
        }
        var context = FHIRInstantiationContext(strict: false)
        let resource : T
        
        if "QuestionnaireResponse" == json["resourceType"] as? String {
            resource = QuestionnaireResponseR4(json: json, owner: nil, context: &context) as! T
        }
        else {
            resource = QuestionnaireR4(json: json, owner: nil, context: &context) as! T
        }
        try context.validate()
        return resource
        
    }
}


public class AQServer : SMART.FHIRMinimalServer {
    
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
        let handler = AQFHIRJSONRequestHandler(method, resource: resource)
        handler.options.insert(.lenient)
        return handler
    }
    
    public override func configurableRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        let basic = "\(client_id!):\(client_secret!)"
        request.setValue("Basic \(basic.sm_base64encoded())", forHTTPHeaderField: "Authorization")
        return request
    }

    
    public func discover(callback : @escaping (([QuestionnaireR4]?, Error?) -> Void)) {
        
        let handler = FHIRJSONRequestHandler(.GET)
        performRequest(against: "Questionnaire?_summary=true", handler: handler) { (response) in
            let jsonresponse = response as! FHIRServerJSONResponse
            
            if let entries = jsonresponse.json?["entry"] as? [FHIRJSON] {
                do {
                    if let questionnaires = try self.summarizeQuestionnairesInSTU3(json: entries) {
                        callback(questionnaires, nil)
                    }
                }
                catch {
                    callback(nil, SMError.adaptiveQuestionnaireErrorMappingToSTU3)
                }
            }
            callback(nil, nil)
        }
    }
    
    func summarizeQuestionnairesInSTU3(json: [FHIRJSON]) throws -> [QuestionnaireR4]? {
        
        let qresources = json.map { (jsonObj) -> FHIRJSON in
            return jsonObj["resource"] as! FHIRJSON
        }
        
        let questionnaires = qresources.map { (jsonResource) -> QuestionnaireR4? in
            
            do {
                let q = try QuestionnaireR4.init(json: jsonResource)
                return q
            }
            catch {
                print(error)
                return nil
            }

            
        }
        
        
        return questionnaires.filter{ $0 != nil } as? [QuestionnaireR4]
    }
}


public class AQClient {
    
}


public extension AQClient {
    
    public class func test() {
        
        let base = "https://mss.fsm.northwestern.edu/AC_API/2018-10/"
        let usr  = "2F984419-5008-4E42-8210-68592B418233"
        let pass = "21A673E8-9498-4DC2-AAB6-07395029A778"
        let authType = "client_credentials"
        let settings = [
            "client_id" : usr,
            "client_secret" : pass
        ]
        
    
        
        let server = AQServer(baseURL: URL(string: base)!, auth: settings)
        QuestionnaireR4.read("96FE494D-F176-4EFB-A473-2AB406610626", server: server, callback: { (questionnaire, error) in
            
            if let r4 = questionnaire as? QuestionnaireR4 {
                r4.item = nil
                let qr = try! QuestionnaireResponseR4.sm_body(contained: r4)
                r4.next_q(server: server, questionnaireResponse: qr) { (resource, error) in
                    do {
                        if let resource = resource as? QuestionnaireResponseR4 {
                            if let questionnaire = resource.contained?.first as? QuestionnaireR4 {
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

        QuestionnaireR4.read("96FE494D-F176-4EFB-A473-2AB406610626", server: server, callback: { (questionnaire, error) in
            
            if let r4 = questionnaire as? QuestionnaireR4 {
                
                
                
                r4.ip_taskController(for: PROMeasure(), callback: { (taskViewController, error) in

                    if let tvc = taskViewController {
                        vc.present(tvc, animated: true, completion: nil)
                    }
                })
            }
            
            
        })
        
        
        
        
        
    }
}
