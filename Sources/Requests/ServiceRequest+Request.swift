//
//  RequestProtocol+FHIR.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension ServiceRequest: Request {
    
    public var rq_identifier: String {
        return id!.string
    }
    
    public var rq_title: String? {
        return code?.text?.string ?? code?.coding?.first?.display?.string ?? category?.first?.text?.string ?? "REQ #\(self.id!.string)"
    }
    
    public var rq_requesterName: String? {
        
        if let practitioner = requester?.resolved(Practitioner.self) {
            return practitioner.name?.first?.human
        }

        if let device = requester?.resolved(Device.self) {
            return "Device #\(device.id!.string)"
        }
        
        return nil
    }
    
    public var rq_requesterEntity: String? {
        if let org = requester?.resolved(Organization.self) {
            return org.name?.string
        }
        return nil
    }
    
    public var rq_requestDate: Date? {
        return authoredOn?.nsDate
    }
    
    public var rq_categoryCode: String? {
        return category?.first?.coding?.first?.code?.string
    }
    
    public var rq_schedule: TaskSchedule? {
        set { }
        get { return sm_Schedule()  }
    }
    
    public static var rq_fetchParameters: [String : String]? {
        return ["status": "active,completed"]
    }
    
    
    public func rq_updated(_ completed: Bool, callback: @escaping ((_ success: Bool) -> Void)) {
        
        if completed {
            self.status = RequestStatus.completed
            self.update { (error) in
                if nil == error {
                    callback(true)
                }
                else {
                    callback(false)
                }
            }
        }
    }
    

    
    public func rq_resolveReferences(callback: @escaping ((Bool) -> Void)) {
        
        guard let ref = requester?.reference?.string else {
            callback(true)
            return
        }
        
        if ref.contains("Practitioner/") {
            requester!.resolve(Practitioner.self, callback: { (_) in
                callback(true)
            })
        }
            
        else if ref.contains("Device/") {
            requester!.resolve(Device.self, callback: { (_ ) in
                callback(true)
            })
        }
        
        else {
            callback(true)
        }
        
    }

    
    public func rq_resolveInstrument(callback: @escaping ((Instrument?, Error?) -> Void)) {
        
        if let questionnaireExtension = extensions(forURI: kSD_QuestionnaireRequest)?.first {
            questionnaireExtension.valueReference?.resolve(Questionnaire.self, callback: { (questionnaire) in
                if let questionnaire = questionnaire {
                    callback(questionnaire, nil)
                }
                else {
                    callback(nil, SMError.promeasureOrderedInstrumentMissing)
                }
            })
        }
        else if let coding = ep_coding(for: "http://researchkit.org"), let code = coding.code?.string {
            
            if let instr = Instruments.ActiveTasks(rawValue: code)?.instance {
                callback(instr, nil)
            }
            else {
                callback(nil, SMError.promeasureOrderedInstrumentMissing)
            }
        }
        else {
            callback(nil, SMError.promeasureOrderedInstrumentMissing)
        }
    }
    
    
    public func rq_configureNew(for instrument: Instrument, schedule: TaskSchedule?, patient: Patient?, practitioner: Practitioner?) throws {

        do {
            status = .active
            intent = .order
            category = [CodeableConcept.sm_RequestCode_EvaluationProcedure()]
            subject = try patient?.asRelativeReference()
            
            // Instrument
            if let questionnaire = instrument as? Questionnaire {
                let qExtension = Extension()
                /*
                 TODO: Better way to check instrument provenance
                */
                if patient?._server?.baseURL.absoluteString == questionnaire._server?.baseURL.absoluteString {
                    qExtension.valueReference = try questionnaire.asRelativeReference()
                }
                else {
                    if let url = questionnaire.url {
                        let reference = Reference()
                        reference.reference = url.absoluteString.fhir_string
                        reference.display = questionnaire.sm_displayTitle()?.fhir_string
                        qExtension.valueReference = reference
                    }
                }
                qExtension.url = kSD_QuestionnaireRequest.fhir_string
                extension_fhir = [qExtension]
            }
            else {
                code = CodeableConcept.sm_From(instrument)
            }
            
            // Requester
            if let practitioner = practitioner {
                requester = try practitioner.asRelativeReference()
            }
            
            // Schedule
            if let schedule = schedule {
                
                if let repeatingSchedule = schedule.occuranceTiming() {
                    occurrenceTiming = repeatingSchedule
                }
                else if let fhir_period = schedule.occurancePeriod() {
                    occurrencePeriod = fhir_period
                }
            }
            else {
                occurrenceDateTime = DateTime.now
            }
        }
        catch {
            throw error
        }
    }


    
}




extension ServiceRequest {
    
    
    public func sm_Schedule() -> TaskSchedule? {
        
        if let occuranceDate = occurrenceDateTime?.nsDate {
            return TaskSchedule(dueDate: occuranceDate)
        }
        
        if let bounds = occurrencePeriod {
            return TaskSchedule(occurancePeriod: bounds)
        }
        
        if let repeating = occurrenceTiming {
            return TaskSchedule(occuranceTiming: repeating)
        }
        
//        if let (start, end, freqValue, freqPeriodUnit, numberOfFreqPeriods) = period_frequency {
//            let period = TaskSchedule.Period(start, end, Calendar.current)
//            let frequency = TaskSchedule.Frequency(times: freqValue, periodType: freqPeriodUnit, numberOfPeriods: numberOfFreqPeriods)
//            return TaskSchedule(period: period, frequency: frequency)
//        }
        
        return nil
        
    }
    
    var period_frequency : (start: Date, end:Date, freqValue:Int, freqPeriodUnit: String, numberOfFreqPeriods: Decimal)? {
        
        guard let timing = self.occurrenceTiming else {
            return nil
        }
        let start = timing.repeat_fhir!.boundsPeriod!.start!.nsDate
        let end = timing.repeat_fhir!.boundsPeriod!.end!.nsDate
        let freqPeriodUnit = timing.repeat_fhir!.periodUnit!.string
        let numberOfFreqPeriods = timing.repeat_fhir!.period!.decimal
        let freqValue = timing.repeat_fhir!.frequency!.int
        return (start, end, freqValue, freqPeriodUnit, numberOfFreqPeriods)
    }
    
   
    
}
