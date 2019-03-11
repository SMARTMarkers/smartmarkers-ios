//
//  RequestProtocol+FHIR.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension ProcedureRequest: RequestProtocol {

 
    public var rq_identifier: String {
        return id!.string
    }
    
    public var rq_title: String? {
        return code?.text?.string ?? category?.first?.text?.string ?? "REQ #\(self.id!.string)"
    }
    
    public var rq_requesterName: String? {
        return requester?.agent?.display?.string.uppercased()
    }
    
    public var rq_requesterEntity: String? {
        return requester?.onBehalfOf?.display?.string
    }
    
    public var rq_requestDate: Date? {
        return authoredOn?.nsDate
    }
    
    public var rq_categoryCode: String? {
        return category?.first?.coding?.first?.code?.string
    }
    
    public var rq_schedule: Schedule? {
        return sm_Schedule()
    }
    
    public static var rq_fetchParameters: [String : String]? {
        return ["status": "active"]
    }
    
    public func rq_updateSchedule(schedule: Schedule) -> Bool {
        return true
    }
    
    public func rq_instrumentResolve(callback: @escaping ((InstrumentProtocol?, Error?) -> Void)) {
        if let questionnaireExtension = extensions(forURI: kStructureDefinition_QuestionnaireRequest)?.first {
            questionnaireExtension.valueReference?.resolve(Questionnaire.self, callback: { (questionnaire) in
                if let questionnaire = questionnaire {
                    callback(questionnaire, nil)
                }
            })
        }
        else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
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
    
    var ep_period_frequency : (start: Date, end:Date, freqValue:Int, freqUnit: String)? {
        guard let timing = self.occurrenceTiming else {
            return nil
        }
        let start = timing.repeat_fhir!.boundsPeriod!.start!.nsDate
        let end = timing.repeat_fhir!.boundsPeriod!.end!.nsDate
        let freqUnit = timing.repeat_fhir!.periodUnit!.string
        let freqValue = timing.repeat_fhir!.frequency!.int
        return (start, end, freqValue, freqUnit)
    }
    
    var ep_dateTime : Date? {
        guard let dateTime = self.occurrenceDateTime else {
            return nil
        }
        
        let dueDate = dateTime.nsDate
        return dueDate
    }
}
