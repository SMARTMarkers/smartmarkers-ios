//
//  QuestionnaireR4.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension Questionnaire {
    
    public func next_q(server: FHIRServer, answer: QuestionnaireResponseItem?, forQuestionnaireItemLinkId: String?, options: FHIRRequestOption, for currResponse: QuestionnaireResponse? = nil,callback: @escaping (_ resource: QuestionnaireResponse?, _ error: Error?) -> Void) {
        
        let response = currResponse ?? self.ResponseBody(responseIdentifier: UUID().uuidString)
        
        if let answer = answer {
            var items = response?.item ?? [QuestionnaireResponseItem]()
            items.append(answer)
            response?.item = items
        }
        
        guard let url = url else {
            callback(nil, FHIRError.requestNotSent("Questionnaire has no url"))
            return
        }
        
        guard let handler = server.handlerForRequest(withMethod: .POST, resource: response) else {
            callback(nil, FHIRError.requestNotSent("Handler could not be created"))
            return
        }
        
        let path = url.absoluteString + "/next-q"
        
        server.performRequest(against: path, handler: handler) { [weak self] (response) in

            if nil == response.error {
                self?._server = server
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



extension Questionnaire {
    
    public func ResponseBody(responseIdentifier: String, answer: Any? = nil) -> QuestionnaireResponse? {
        
        let qr = QuestionnaireResponse()
        qr.id = FHIRString(responseIdentifier)
        
        let meta = Meta()
        meta.profile = [FHIRCanonical(kSD_adaptive_QuestionnaireResponse)!]
        qr.meta = meta
        let exts = [
            Extension(FHIRURL(kSD_adaptive_QuestionnaireExpiration)!, DateTime.now),
            Extension(FHIRURL(kSD_adaptive_QuestionnaireFinished)!, nil)
        ]
        qr.extension_fhir = exts
        qr.status = QuestionnaireResponseStatus.inProgress
        qr.authored = DateTime.now
        
        let containedQ = Questionnaire()
        containedQ.meta = meta
        containedQ.meta?.profile = [FHIRCanonical(kSD_adaptive_Questionnaire)!]
        containedQ.id = id
        containedQ.url = url
        containedQ.title = title
        containedQ.status = status
        containedQ.subjectType = subjectType
        
        containedQ.item = []
        qr.contained = [containedQ]
        return qr
    }
    
}

extension SMART.Extension {
    
    convenience init(_ url: FHIRURL, _ dateTime: DateTime?) {
        self.init(url: url.absoluteString.fhir_string)
        self.valueDateTime = dateTime
    }
}
