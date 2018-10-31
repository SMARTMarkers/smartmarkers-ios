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
	
	
	var ep_titleCode : String? {
		get {
			if let text = self.code?.text?.string { return text }
			return nil
		}
	}
	
	var ep_titleCategory : String? {
		get {
			return self.category?.first?.text?.string
		}
	}
    
    public func ep_coding(for system: String) -> Coding? {
        
        if let codeConcept = code {
			return codeConcept.ep_coding(for: system)
        }
        return nil
    }
	
	public func ep_loincCode() -> String? {
		return ep_coding(for: "http://loinc.org")?.code?.string
	}
	

	
	

}

extension CodeableConcept {
	
	public func ep_coding(for systemURI: String) -> Coding? {
		return self.coding?.filter { $0.system?.absoluteString == systemURI }.first
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
extension Questionnaire {
	
	/// Best possible title for the Questionnaire
	public func ep_displayTitle() -> String {
		
		if let name 	= name { return name.string }
		if let title	= title	{	return title.string }
		
		if let identifier = self.identifier {
			for iden in identifier {
				if let value = iden.value {
					return value.string
				}
			}
		}
		
		if let codes = self.code {
			for code in codes {
				if let display = code.display {
					return display.string
				}
			}
		}
		
		return self.id!.string
	}
}

