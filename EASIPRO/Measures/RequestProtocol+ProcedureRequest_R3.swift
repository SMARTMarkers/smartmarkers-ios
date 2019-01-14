//
//  RequestProtocol+FHIR.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/// `ProcedureRequest` conforming to the RequestProtocol
extension ProcedureRequest : PrescribingResource_Protocol {
    
    /// Initalizes `Schedule` from the conformant resource FHIR ProcedureRequest
    public func getSchedule() -> Schedule? {
        return self.sm_Schedule()
    }
    
    /// Requester Name
    public var pro_prescriberName: String? {
        return requester?.agent?.display?.string.uppercased()
    }
    
    /// Requester Ontological reference
    public var pro_code: [Coding]? {
        return code?.coding
    }
    
    /// Request category; often "survey type"
    public var pro_categoryText: String? {
        return category?.first?.text?.string
    }
    
    
    public var pro_title: String? {
        return code?.text?.string ?? category?.first?.text?.string ?? "REQ #\(self.id!.string)"
    }
    
    public func resolveInstrument(callback : @escaping ((_ instrument: InstrumentResourceProtocol?) -> Void)) {
        if let questionnaireExtension = extensions(forURI: kStructureDefinition_QuestionnaireRequest)?.first {
            questionnaireExtension.valueReference?.resolve(Questionnaire.self, callback: { (questionnaire) in
                if let questionnaire = questionnaire {
                    let instrument = InstrumentResource(questionnaire)
                    callback(instrument)
                }
                else {
                    callback(nil)
                }
            })
        }
        else {
            callback(nil)
        }
        
    }
}



extension ProcedureRequest {
    
    public func sm_Schedule() -> Schedule? {
        
        if let occuranceDate = self.ep_dateTime {
            return Schedule(dueDate: occuranceDate)
        }
        else if let (start, end, fValue, fUnit) = self.ep_period_frequency {
            let period = PeriodBound(start, end)
            let frequence = Frequency(value: fValue, unit: fUnit)
            return Schedule(period: period, freq: frequence)
        }
        else {
            return nil
        }
    }
}
