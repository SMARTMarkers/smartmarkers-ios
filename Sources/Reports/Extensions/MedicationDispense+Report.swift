//
//  MedicationDispense+Report.swift
//  PPMG
//
//  Created by raheel on 3/24/22.
//

import Foundation
import SMARTMarkers
import SMART

extension MedicationDispense: Report {
    
    public var rp_identifier: String? {
        id?.string
    }
    
    public var rp_title: String? {
        medicationCodeableConcept?.text?.string ??
        rp_code?.display?.string ??
        rp_code?.code?.string
    }
    
    public var rp_code: Coding? {
        medicationCodeableConcept?.coding?.first ??
        medicationReference?.resolved(Medication.self)?.code?.coding?.first
    }
    
    public var rp_description: String? {
        nil
    }
    
    public var rp_date: Date? {
        whenHandedOver?.nsDate ?? whenPrepared?.nsDate
    }
    
    public var rp_observation: String? {
        status?.rawValue
    }
    
    @discardableResult
    public func sm_assign(patient: Patient) -> Bool {
        
        if let patientReference = try? patient.asRelativeReference() {
            subject = patientReference
            
            return true
        }
        
        return false
    }
    
    
    
}
