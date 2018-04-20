//
//  EASIPRO+SwiftFHIR.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 27/02/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension Appointment {
	
	public func ep_patientReferences() -> [String]? {
		
		guard let participant = participant else {
			return nil
		}
		
		var patientReferences = [String]()
		for p in participant {
			if let reference = p.actor, let referenceString = reference.reference, referenceString.string.contains("Patient/") {
				let fhirID = referenceString.string.components(separatedBy: "/")[1]
				patientReferences.append(fhirID)
			}
		}
		
		return (patientReferences.count > 0) ? patientReferences : nil
	}
	
}

extension ProcedureRequest {
    
    open class func ep_instant(for patient: Patient, measure: PROMeasure, practitioner: Practitioner) -> ProcedureRequest? {
        if let questionnaire = measure.measure as? Questionnaire {
            return ProcedureRequest.ep_instant(for: patient, questionnaire: questionnaire , practitioner: practitioner)
        }
        return nil
    }
    
    open class func ep_instant(for patient: Patient, questionnaire: Questionnaire?, practitioner: Practitioner) -> ProcedureRequest {
        print(questionnaire)
        print(practitioner)
        
    
        let pr = ep_instant_template(for: patient, practitioner: practitioner)
        // Adopt from Questionnaire
        let codingP = Coding.ep_with(system: "http://loinc.org", code: "61952-8", display: "PROMIS Bank v1.0 - Depression")
        let conceptP = CodeableConcept()
        conceptP.text = FHIRString("PROMIS Bank v1.0 - Depression")
        conceptP.coding = [codingP]
        pr.code = conceptP
        
        
        
        
        print(pr.debugDescription)
        print(pr.description)
        print(pr.category)
        
        return pr
        
    }
    
    
    open class func ep_instant_template(for patient: Patient, practitioner: Practitioner) -> ProcedureRequest {
        
        let pr = ProcedureRequest()
        pr.status = RequestStatus.active
        pr.intent = RequestIntent.plan
        let now = DateTime.now
        pr.authoredOn = now
        pr.occurrenceDateTime = now
        
        //Patient Reference
        let patientReference = try! patient.reference(resource: patient)
        pr.subject = patientReference
        
        //Practitioner Reference
        let practitionerReference = try! practitioner.reference(resource: practitioner, withDisplay: practitioner.name?.first?.human?.fhir_string)
        pr.requester = ProcedureRequestRequester(agent: practitionerReference)
        
        //coding
        let concept = CodeableConcept()
        concept.text = FHIRString("Evaluation")
        let coding = Coding()
        coding.system = FHIRURL.init("http://snowmed.info/sct")
        coding.code   = FHIRString("386053000")
        coding.display = FHIRString("Evaluation procedure (procedure)")
        concept.coding = [coding]
        pr.category = [concept]
        
        return pr
    }

}


extension Patient {
	
	public func ep_MRNumber() -> String {
		
		if let identifier = identifier {
			
			let filtered = identifier.filter({ (iden) -> Bool in
				if let mrCode = iden.type?.coding?.filter({ (coding) -> Bool in
					return coding.code?.string == "MR"
				}) {
					return mrCode.count > 0
				}
				return false
			})
			
			if filtered.count > 0, let mrIdentifier = filtered.first {
				return "MRN: \(mrIdentifier.value!.string.uppercased())"
			}
		}
		return "MRN: NA"
	}
	
}


extension Coding {
    
    public class func ep_with(system: String, code: String, display: String) -> Coding {
        
        let coding = Coding()
        coding.system = FHIRURL(system)
        coding.code   = code.fhir_string
        coding.display = display.fhir_string
        return coding
        
    }
}


extension Observation {
    
    class func ep_for(procedureRequest: ProcedureRequest, score: String) {
        
    }
}

