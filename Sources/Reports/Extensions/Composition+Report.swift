//
//  Composition+Report.swift
//  PPMG
//
//  Created by raheel on 5/23/22.
//

import SMARTMarkers
import SMART

extension Composition: Report {
    
    public var rp_identifier: String? {
        id?.string
    }
    
    public var rp_title: String? {
        title?.string
    }
    
    public var rp_code: Coding? {
        self.type?.coding?.first
    }
    
    public var rp_description: String? {
        nil
    }
    
    public var rp_date: Date? {
        date?.nsDate
    }
    
    public var rp_observation: String? {
        nil
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


extension Report where Self == Composition {
    
    static func ppmg_compose(author: Reference, title: String, code: Coding, resources: [Report], for patient: Patient?) -> Composition {
        
        
        let composition = Composition(author: [author],
                                      date: DateTime.now,
                                      status: .final,
                                      title: title.fhir_string,
                                      type: code.sm_asCodeableConcept(nil))
        let sections = resources.map { report -> CompositionSection in
            let entry = CompositionSection()
            entry.title = report.rp_title?.fhir_string
            entry.code = report.rp_code?.sm_asCodeableConcept(nil)
            if let containedRef = try? composition.contain(resource: report, withDisplay: nil) {
                entry.entry = [containedRef]
            }
            return entry
        }
        
        
        composition.section = sections
        
        return composition
        
    }
}
