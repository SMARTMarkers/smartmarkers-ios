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

    
    public func rq_instrumentResolve(callback: @escaping ((Instrument?, Error?) -> Void)) {
        
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
        else if let coding = ep_coding(for: "http://researchkit.org") {
            
            if let instr = Instruments.ActiveTasks.init(rawValue: coding.code!.string)?.instance {
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
                qExtension.valueReference = try questionnaire.asRelativeReference()
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
            if let _ = schedule {
                
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
        
        if let (start, end, frequencyValue, frequencyUnit) = period_frequency {
            let period = TaskSchedule.Period(start: start, end: end, calender: Calendar.current)
            let frequency = TaskSchedule.Frequency(value: frequencyValue, unit: frequencyUnit)
            return TaskSchedule(period: period, frequency: frequency)
        }
        
        return nil
        
    }
    
    var period_frequency : (start: Date, end:Date, freqValue:Int, freqUnit: String)? {
        guard let timing = self.occurrenceTiming else {
            return nil
        }
        let start = timing.repeat_fhir!.boundsPeriod!.start!.nsDate
        let end = timing.repeat_fhir!.boundsPeriod!.end!.nsDate
        let freqUnit = timing.repeat_fhir!.periodUnit!.string
        let freqValue = timing.repeat_fhir!.frequency!.int
        return (start, end, freqValue, freqUnit)
    }
    
   
    
}
