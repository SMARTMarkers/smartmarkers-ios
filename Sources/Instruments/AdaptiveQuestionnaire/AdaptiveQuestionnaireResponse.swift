//
//  QuestionnaireResponseR4.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/29/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART



extension AdaptiveQuestionnaire {
    
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

extension QuestionnaireResponse {
    
    public class func sm_AdaptiveQuestionnaireBody(contained questionnaire: Questionnaire, answer: Any? = nil) throws -> QuestionnaireResponse? {
        
        let qr = QuestionnaireResponse()
        qr.id = FHIRString("rtest")
        
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
        containedQ.meta = questionnaire.meta
        containedQ.meta?.profile = [FHIRCanonical(kSD_adaptive_Questionnaire)!]
        containedQ.id = questionnaire.id
        containedQ.url = questionnaire.url
        containedQ.title = questionnaire.title
        containedQ.status = questionnaire.status
        containedQ.subjectType = questionnaire.subjectType
        
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
