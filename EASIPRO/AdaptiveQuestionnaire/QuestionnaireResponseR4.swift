//
//  QuestionnaireResponseR4.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/29/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART




extension QuestionnaireResponse {
    
    public class func sm_AdaptiveQuestionnaireBody(contained questionnaire: Questionnaire, answer: Any? = nil) throws -> QuestionnaireResponse? {
        
        let qr = QuestionnaireResponse()
        qr.id = FHIRString("rtest")
        
        let meta = Meta()
        meta.profile = [FHIRURL(kSDC_adaptive_QuestionnaireResponse)!]
        qr.meta = meta
        let exts = [
            Extension(FHIRURL(kSDC_adaptive_QuestionnaireExpiration)!, DateTime.now),
            Extension(FHIRURL(kSDC_adaptive_QuestionnaireFinished)!, nil)
        ]
        qr.extension_fhir = exts
        qr.status = QuestionnaireResponseStatus.inProgress
        qr.authored = DateTime.now
        
        let containedQ = Questionnaire()
        containedQ.meta = questionnaire.meta
        containedQ.meta?.profile = [FHIRURL(kSDC_adaptive_Questionnaire)!]
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
