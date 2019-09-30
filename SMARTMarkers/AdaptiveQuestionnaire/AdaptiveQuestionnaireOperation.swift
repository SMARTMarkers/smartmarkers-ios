//
//  QuestionnaireR4.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension Questionnaire {
    
    public func next_q(server: FHIRMinimalServer, questionnaireResponse: QuestionnaireResponse?, options: FHIRRequestOption = [], callback: @escaping FHIRResourceErrorCallback) {
        
        guard let id = id, let questionnaireResponse = questionnaireResponse else {
            callback(nil, FHIRError.requestNotSent("Questionnaire has no id"))
            return
        }
        guard var handler = server.handlerForRequest(withMethod: .POST, resource: questionnaireResponse) else {
            callback(nil, FHIRError.noRequestHandlerAvailable(.POST))
            return
        }
        
        handler.options.insert(.lenient)

        //todo:
        /*
         
         path should be Questionnaire.url full path, and append next-q
         */
        
        let path = "Questionnaire/\(id.string)/next-q"
        
        
        
        server.performRequest(against: path, handler: handler) { (response) in
            
            if nil == response.error {
                self._server = server
                do {
                    let resource = try response.responseResource(ofType: QuestionnaireResponse.self)
                    resource._server = server
                    callback(resource, nil)
                    
                }
                catch {
                    callback(nil, error.asFHIRError)
                }
            }
            else {
                
                callback(nil, response.error)
            }
        }
        
    }
}


