//
//  QuestionnaireResponseR4.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/29/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART





open class QuestionnaireResponseR4: QuestionnaireResponse {
    
    
    override open func populate(from json: FHIRJSON, context instCtx: inout FHIRInstantiationContext) {
        
        super.populate(from: json, context: &instCtx)
        
        contained = createInstances(of: QuestionnaireR4.self, for: "contained", in: json, context: &instCtx, owner: self) ?? contained

    }
    
    
    override open func decorate(json: inout FHIRJSON, errors: inout [FHIRValidationError]) {
        
//        bugWorkaround(json: &json)
        super.decorate(json: &json, errors: &errors)
        
        arrayDecorate(json: &json, withKey: "contained", using: self.contained, errors: &errors)

        

    }
    
    func bugWorkaround(json: inout FHIRJSON) {
        
        if let item = item {
            for itm in item {
                if var ans = itm.answer {
                    if ans.count > 1 {
                        ans.remove(at: 0)
                        itm.answer = ans
                    }
                }
            }
        }
        
    }

}

extension QuestionnaireResponseR4 {
    
    public class func sm_body(contained questionnaire: QuestionnaireR4, answer: Any? = nil) throws -> QuestionnaireResponseR4? {
        
        let qr = QuestionnaireResponseR4()
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
        
        let containedQ = QuestionnaireR4()
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
